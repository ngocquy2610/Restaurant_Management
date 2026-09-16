class Order < ApplicationRecord
  belongs_to :table
  belongs_to :waiter, class_name: "User", foreign_key: "user_id", optional: true
  belongs_to :reservation, optional: true

  has_many :payments, dependent: :restrict_with_error
  belongs_to :promotion, optional: true

  has_many :order_items, dependent: :destroy
  accepts_nested_attributes_for :order_items, allow_destroy: true,
    reject_if: :order_item_dropped?

  enum :status, {
    preorder: 0,
    inserve: 1,
    completed: 2
  }, default: :inserve

  validates :table, presence: true

  before_validation :set_table_price, if: -> { table.present? && table_price.blank? }
  after_create  :sync_table!
  after_update  :sync_table!, if: -> { saved_change_to_status? }
  after_save    :recalculate_total_price!, if: -> { table_price_changed? || order_items.any? }

  def set_table_price
    self.table_price = table.table_type.price_add_on
  end

  def recalculate_total_price!
    total = table_price.to_f + order_items.sum { |oi| oi.unit_price.to_f * oi.quantity.to_i }
    total = total.round(2)

    if persisted?
      update_columns(total_price: total) unless total_price == total
    else
      self.total_price = total
    end
  end

  def sync_table!
    target =
      case status.to_sym
      when :preorder  then :reserved
      when :inserve   then :occupied
      when :completed then :available
      else :available
      end
    table.update!(status: target) if table.present? && table.status.to_sym != target
  end

  private

  def order_item_dropped?(attributes)
    attributes[:food_id].blank? && !ActiveModel::Type::Boolean.new.cast(attributes[:_destroy])
  end
end
