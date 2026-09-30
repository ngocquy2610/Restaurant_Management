class StockTransaction < ApplicationRecord
  belongs_to :ingredient
  belongs_to :user, optional: true

  enum :transaction_type, { stock_in: 0, stock_out: 1, adjustment: 2, waste: 3 },
       default: :stock_in

  scope :recent, -> { order(created_at: :desc) }

  validates :quantity, presence: true, numericality: { greater_than: 0 }

  before_validation :fill_quantities, on: :create

  def signed_quantity
    case transaction_type.to_sym
    when :stock_in          then  quantity.to_d
    when :stock_out, :waste then -quantity.to_d
    else                         quantity.to_d
    end
  end

  private

  def fill_quantities
    return if ingredient.blank?

    before = ingredient.current_quantity.to_d
    self.quantity_before = before
    self.quantity_after  = before + signed_quantity
    ingredient.current_quantity = quantity_after   # before_save của Ingredient tự sync status
  end
end
