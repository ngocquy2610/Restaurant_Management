class Inventory::ReportsController < Inventory::BaseController
  MAX_RANGE_DAYS = 366 # limit in 1 year

  def index
    @from_date, @to_date, @range_error = resolve_range
    @time_range = @from_date.beginning_of_day..@to_date.end_of_day
    # .beginning_of_day --> 00:00:00
    # .end_of_day --> 23:59:59

    @stock_transactions = policy_scope(StockTransaction)
                            .where(created_at: @time_range)
                            .includes(:ingredient, :user)
                            .order(created_at: :desc)

    @stock_ins = @stock_transactions.where(transaction_type: :stock_in)
    @stock_outs = @stock_transactions.where(transaction_type: :stock_out)

    @ingredients = policy_scope(Ingredient).active
    @ingredient_summary = build_ingredient_summary
    @report_summary = build_report_summary

    @total_ingredients = @report_summary[:total_ingredients]
    @total_stock_value = @report_summary[:total_stock_value]
    @low_stock_count = @report_summary[:low_stock_count]
    @out_of_stock_count = @report_summary[:out_of_stock_count]

    @ingredient_movements = build_ingredient_movements

    @paginated_ingredients = @ingredients.page(params[:ingredients_page]).per(10)

    @restock_tasks = policy_scope(RestockTask)
                        .where(created_at: @time_range)
                        .includes(:ingredient)

    @restock_summary = build_restock_summary

    @total_restock_tasks = @restock_summary[:total]
    @completed_restock_tasks = @restock_summary[:completed]
    @pending_restock_tasks = @restock_summary[:pending]
    @expected_quantity = @restock_summary[:expected_quantity]
    @received_quantity = @restock_summary[:received_quantity]

    @paginated_restock_tasks = @restock_tasks.page(params[:restock_tasks_page]).per(10)

    @paginated_stock_transactions = @stock_transactions.page(params[:transactions_page]).per(15)

    @stock_transactions_count = @stock_transactions.count
  end

  private

  def build_report_summary
    summary = Ingredient.connection.select_one(<<~SQL)
      SELECT
        COUNT(*) AS total_ingredients,
        COALESCE(SUM(current_quantity * unit_cost), 0) AS total_stock_value,
        SUM(CASE WHEN current_quantity > 0 AND current_quantity <= low_stock_threshold THEN 1 ELSE 0 END) AS low_stock_count,
        SUM(CASE WHEN current_quantity = 0 THEN 1 ELSE 0 END) AS out_of_stock_count
      FROM ingredients
      WHERE active = TRUE
    SQL

    {
      total_ingredients: summary["total_ingredients"].to_i,
      total_stock_value: summary["total_stock_value"].to_d,
      low_stock_count: summary["low_stock_count"].to_i,
      out_of_stock_count: summary["out_of_stock_count"].to_i
    }
  end

  def build_restock_summary
    summary = RestockTask.connection.select_one(<<~SQL)
      SELECT
        COUNT(*) AS total,
        SUM(CASE WHEN status = 2 THEN 1 ELSE 0 END) AS completed,
        SUM(CASE WHEN status IN (0, 1) THEN 1 ELSE 0 END) AS pending,
        COALESCE(SUM(quantity), 0) AS expected_quantity,
        COALESCE(SUM(COALESCE(received_quantity, 0)), 0) AS received_quantity
      FROM restock_tasks
      WHERE created_at BETWEEN '#{@time_range.begin}' AND '#{@time_range.end}'
    SQL

    {
      total: summary["total"].to_i,
      completed: summary["completed"].to_i,
      pending: summary["pending"].to_i,
      expected_quantity: summary["expected_quantity"].to_d,
      received_quantity: summary["received_quantity"].to_d
    }
  end

  def build_ingredient_summary
    summary = build_report_summary

    {
      total: summary[:total_ingredients],
      stock_value: summary[:total_stock_value],
      low_stock: summary[:low_stock_count],
      out_of_stock: summary[:out_of_stock_count]
    }
  end

  def build_ingredient_movements
    period_days = [(@to_date - @from_date).to_i + 1, 1].max

    aggregated_transactions = StockTransaction.connection.select_all(<<~SQL).each_with_object({}) do |row, hash|
      SELECT
        ingredient_id,
        SUM(CASE WHEN transaction_type = 0 THEN quantity ELSE 0 END) AS received,
        SUM(CASE WHEN transaction_type = 1 THEN quantity ELSE 0 END) AS issued,
        SUM(CASE WHEN transaction_type = 3 THEN quantity ELSE 0 END) AS wasted
      FROM stock_transactions
      WHERE created_at BETWEEN '#{@time_range.begin}' AND '#{@time_range.end}'
      GROUP BY ingredient_id
    SQL
      hash[row["ingredient_id"].to_i] = {
        received: row["received"].to_d,
        issued: row["issued"].to_d,
        wasted: row["wasted"].to_d
      }
    end

    @ingredients.each_with_object({}) do |ingredient, movements|
      metrics = aggregated_transactions[ingredient.id] || { received: 0.to_d, issued: 0.to_d, wasted: 0.to_d }
      received = metrics[:received]
      issued = metrics[:issued]
      wasted = metrics[:wasted]

      average_daily_issue = issued / period_days

      days_left =
        if average_daily_issue.positive?
          ingredient.current_quantity.to_d / average_daily_issue
        end

      movements[ingredient.id] = {
        received: received,
        issued: issued,
        wasted: wasted,
        average_daily_issue: average_daily_issue,
        days_left: days_left
      }
    end
  end

  def resolve_range
    default_to = Date.current # take current date
    default_from = default_to - 29.days # get nearest 30 days

    if params[:from_date].blank? && params[:to_date].blank?
      return [default_from, default_to, nil]
    end

    from = parse_date(params[:from_date])
    to = parse_date(params[:to_date])

    if from.nil? || to.nil?
      [default_from, default_to, "Please enter from-to date"]
    elsif from > to
      [default_from, default_to, "From date invalid"]
    elsif (to-from).to_i > MAX_RANGE_DAYS
      [default_from, default_to, "The limitation range is 1 year"]
    else
      [from, to, nil]
    end
  end

  def parse_date(value)
    Date.iso8601(value.to_s) # YYYY-MM-DD
  rescue ArgumentError
    nil
  end
end