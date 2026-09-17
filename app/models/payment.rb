class Payment < ApplicationRecord
  belongs_to :order
  belongs_to :payment_method
  belongs_to :processed_by,
             class_name: "User",
             optional: true

  after_update :credit_customer_year_spend,
    if: -> { saved_change_to_status? && completed? }

  enum :status, {
    pending: 0,
    completed: 1,
    failed: 2,
    refunded: 3
  }

  validates :subtotal, :discount_amount, :total_amount,
            numericality: { greater_than_or_equal_to: 0 }
  validates :total_amount, numericality: { greater_than: 0 }
  validates :currency, presence: true

  def vietqr_url
    return unless payment_method&.qr?

    ::VietqrUrlBuilder.call(self)
  end

  def total_amount_vnd
    ::VietqrUrlBuilder.amount_in_vnd(self)
  end

  private

  def credit_customer_year_spend
    customer = order.customer
    customer&.increment!(:year_spend, total_amount.to_d)
  end
end