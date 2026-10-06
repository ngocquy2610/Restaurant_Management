class Inventory::ReportsController < Inventory::BaseController
  MAX_RANGE_DAYS = 366 # limit in 1 year

  def index
    @from_date, @to_date, @range_error = resolve_range
    @time_range = @from_date.beginning_of_day..@to_date.end_of_day
      # .beginning_of_day --> 00:00:00
      # .end_of_day --> 23:59:59

    @stock_transactions = policy_scope(StockTransaction).where(created_at: @time_range).includes(:ingredient, :user).order(created_at: :desc)
    @stock_ins = @stock_transactions.where(transaction_type: :stock_in)
    @stock_outs = @stock_transactions.where(transaction_type: :stock_out)

    @ingredients = policy_scope(Ingredient).active
    @total_ingredients = @ingredients.count
    @total_stock_value = @ingredients.sum("current_quantity * unit_cost")
    @low_stock_count = @ingredients.low_stock.count
    @out_of_stock_count = @ingredients.out_of_stock.count
    @ingredient_movements = build_ingredient_movements
    @paginated_ingredients = @ingredients.page(params[:ingredients_page]).per(10)

    @restock_tasks = policy_scope(RestockTask).where(created_at: @time_range).includes(:ingredient)
    @total_restock_tasks = @restock_tasks.count
    @completed_restock_tasks = @restock_tasks.where(status: :completed).count
    @pending_restock_tasks = @restock_tasks.where(status: %i[pending in_progress]).count
    @expected_quantity = @restock_tasks.sum(:quantity)
    @received_quantity = @restock_tasks.sum(:received_quantity)
    @paginated_restock_tasks = @restock_tasks.page(params[:restock_tasks_page]).per(10)
    @paginated_stock_transactions = @stock_transactions.page(params[:transactions_page]).per(15)
    @stock_transactions_count = @stock_transactions.count
  end

  private

  def build_ingredient_movements
    period_days = [ (@to_date - @from_date).to_i + 1, 1 ].max
    transactions_by_ingredient = @stock_transactions.to_a.group_by(&:ingredient_id)

    @ingredients.each_with_object({}) do |ingredient, movements|
      rows = transactions_by_ingredient.fetch(ingredient.id, [])
      received = rows.select(&:stock_in?).sum { |transaction| transaction.quantity.to_d }
      issued = rows.select(&:stock_out?).sum { |transaction| transaction.quantity.to_d }
      wasted = rows.select(&:waste?).sum { |transaction| transaction.quantity.to_d }
      average_daily_issue = issued / period_days
      days_left = average_daily_issue.positive? ? ingredient.current_quantity.to_d / average_daily_issue : nil

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