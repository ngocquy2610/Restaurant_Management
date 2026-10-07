class Ingredient < ApplicationRecord
  CATEGORIES = %w[meat seafood dairy produce dry bakery beverage other].freeze

  has_many :recipe_items, dependent: :restrict_with_error
  has_many :foods, through: :recipe_items
  has_many :stock_transactions, dependent: :restrict_with_error
  has_many :restock_tasks,      dependent: :restrict_with_error
  has_many :low_stock_requests, dependent: :restrict_with_error
  has_many :waste_reports,      dependent: :restrict_with_error

  enum :status, { in_stock: 0, low_stock: 1, out_of_stock: 2 }, default: :in_stock

  scope :needs_restock, -> { where(status: %i[low_stock out_of_stock]) }
  scope :by_category,   ->(category) { where(category: category) if category.present? }

  scope :active,    -> { where(active: true) }
  scope :archived,  -> { where(active: false) }
  scope :search,    ->(term) { where("name ILIKE :t", t: "%#{term.to_s.strip}%") if term.present? }
  scope :by_status, ->(status) { where(status: status) if status.present? && statuses.key?(status) }

  scope :low_stock, -> { where("current_quantity > 0 AND current_quantity <= low_stock_threshold") }
  scope :out_of_stock, -> { where("current_quantity = 0") }

  before_save :sync_status!

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :unit, presence: true, inclusion: { in: %w[kg g liter ml piece] }
  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validates :unit_cost, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :current_quantity,    numericality: { greater_than_or_equal_to: 0 }
  validates :low_stock_threshold, numericality: { greater_than_or_equal_to: 0 }

  def deactivate! = update!(active: false)
  def reactivate! = update!(active: true)

  private

  def sync_status!
    qty       = current_quantity.to_d
    threshold = low_stock_threshold.to_d

    self.status =
      if qty <= 0
        :out_of_stock
      elsif qty <= threshold
        :low_stock
      else
        :in_stock
      end
  end
end
