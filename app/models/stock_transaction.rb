class StockTransaction < ApplicationRecord
  belongs_to :ingredient
  belongs_to :user, optional: true

  enum :transaction_type, { stock_in: 0, stock_out: 1, adjustment: 2, waste: 3 },
       default: :stock_in

  scope :recent, -> { order(created_at: :desc) }
  scope :by_ingredient, ->(id) { where(ingredient_id: id) if id.present? }
  scope :by_type, ->(type) { where(transaction_type: type) if type.present? && transaction_types.key?(type) }
  scope :between, ->(from, to) do
    rel = all
    rel = rel.where("created_at >= ?", Time.zone.parse(from).beginning_of_day) if from.present?
    rel = rel.where("created_at <= ?", Time.zone.parse(to).end_of_day)       if to.present?
    rel
  end

  validates :quantity, presence: true, numericality: { greater_than: 0 }, unless: :adjustment?
  validates :quantity, presence: true, numericality: { other_than: 0 },  if: :adjustment?

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
    return if quantity_before.present? && quantity_after.present?   # service đã set → tôn trọng
    before = ingredient.current_quantity.to_d
    self.quantity_before = before
    self.quantity_after  = before + signed_quantity
  end
end
