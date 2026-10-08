class RestaurantPerformanceService
  def initialize(from_date:, to_date:, time_range:)
    @from_date = from_date
    @to_date = to_date
    @time_range = time_range
  end

  def overview
    {
      net_revenue: revenue[:net],
      gross_profit: profit[:gross_profit],
      gross_margin: profit[:margin],
      occupancy_rate: operations[:occupancy_rate],
      avg_rating: customer[:avg_rating],
      low_stock_count: inventory[:low_stock_count]
    }
  end

  def call
    {
      summary: {
        net_revenue: revenue[:net],
        gross_profit: profit[:gross_profit],
        gross_margin: profit[:margin],
        waste_cost: costs[:waste],
        avg_rating: customer[:avg_rating]
      },
      revenue: revenue,
      costs: costs,
      profit: profit,
      operations: operations,
      customer: customer,
      inventory: inventory,
      reservation_funnel: reservation_funnel,
      daily_trend: daily_trend,
      monthly_trend: monthly_trend
    }
  end

  private

  def revenue
    completed = Payment.where(status: :completed, paid_at: @time_range)
    refunded = Payment.where(status: :refunded, paid_at: @time_range)

    {
      gross: Order.where(created_at: @time_range).sum(:subtotal).to_d,
      net: completed.sum(:total_amount).to_d,
      refund: refunded.sum(:total_amount).to_d,
      by_payment_method: payment_method_breakdown
    }
  end

  def costs
    cogs = OrderItem
      .joins(food_variant: :food)
      .where(created_at: @time_range)
      .sum("order_items.quantity * order_items.unit_price").to_d

    waste = WasteReport
      .where(status: :approved, reviewed_at: @time_range)
      .joins(:ingredient)
      .sum("verified_quantity * ingredients.unit_cost").to_d

    {
      cogs: cogs,
      waste: waste
    }
  end

  def profit
    net = revenue[:net].to_d
    cogs = costs[:cogs].to_d
    waste = costs[:waste].to_d
    gross_profit = net - cogs
    margin = net.positive? ? (gross_profit / net) * 100 : 0.0

    {
      gross_profit: gross_profit,
      margin: margin,
      after_waste: gross_profit - waste
    }
  end

  def operations
    total = Table.count.to_f
    occupied = Table.where(status: :occupied).count.to_f
    completed_payments = Payment.where(status: :completed, paid_at: @time_range)
    payment_count = completed_payments.count

    {
      occupancy_rate: total.positive? ? (occupied / total) * 100 : 0.0,
      aov: payment_count.positive? ? revenue[:net] / payment_count : 0.0,
      order_status: Order.where(created_at: @time_range).group(:status).count
    }
  end

  def customer
    reviews = Review.where(created_at: @time_range)

    {
      avg_rating: reviews.average(:rating).to_f,
      reviews_count: reviews.count,
      low_rating_count: reviews.where("rating <= 2").count
    }
  end

  def inventory
    {
      total_stock_value: Ingredient.where(active: true).sum("current_quantity * unit_cost").to_d,
      low_stock_count: Ingredient.where(active: true).where("current_quantity > 0 AND current_quantity <= low_stock_threshold").count,
      out_of_stock_count: Ingredient.where(active: true).where(current_quantity: 0).count
    }
  end

  def payment_method_breakdown
    Payment
      .where(status: :completed, paid_at: @time_range)
      .joins(:payment_method)
      .group("payment_methods.code")
      .sum(:total_amount)
  end

  def reservation_funnel
    {
      pending: Reservation.where(created_at: @time_range, status: :pending).count,
      approved: Reservation.where(created_at: @time_range, status: :approved).count,
      checked_in: Reservation.where(created_at: @time_range, status: :checked_in).count,
      completed: Reservation.where(created_at: @time_range, status: :completed).count,
      cancelled: Reservation.where(created_at: @time_range, status: :cancelled).count
    }
  end

  def daily_trend
    Payment
      .where(status: :completed, paid_at: @time_range)
      .group("DATE(paid_at)")
      .sum(:total_amount)
  end

  def monthly_trend
    Payment
      .where(status: :completed, paid_at: @time_range)
      .to_a
      .group_by { |payment| payment.paid_at.to_date.beginning_of_month }
      .transform_values { |payments| payments.sum { |payment| payment.total_amount.to_d } }
  end
end