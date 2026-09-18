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
  after_update  :sync_reservation, if: -> { saved_change_to_status? && completed? }
  after_save    :recalculate_total_price!, if: -> { table_price_changed? || order_items.any? }

  def set_table_price
    self.table_price = table.table_type.price_add_on
  end

  def recalculate_total_price!
    calculated_subtotal = table_price.to_d + order_items.sum do |order_item|
      order_item.unit_price.to_d * order_item.quantity.to_i
    end
    calculated_subtotal = calculated_subtotal.round(2)
    discount = membership_discount_amount(calculated_subtotal)
    total = [calculated_subtotal - discount, 0].max.round(2)

    if persisted?
      unless subtotal == calculated_subtotal && discount_amount == discount && total_price == total
        update_columns(subtotal: calculated_subtotal, discount_amount: discount, total_price: total)
      end
    else
      self.subtotal = calculated_subtotal
      self.discount_amount = discount
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

  # When the order is paid (marked completed), close out its linked reservation
  # so the booking is finished and its table is freed.
  def sync_reservation
    reservation&.update!(status: :completed)
  end

  def customer
    reservation&.user || (waiter if waiter&.customer?)
  end

  # Discount percentage granted by the customer's current membership tier.
  def membership_discount_percent
    customer&.current_member_tier&.discount.to_i
  end

  # Dollar value of the membership discount for a given base amount.
  def membership_discount_amount(base = subtotal)
    (base.to_d * membership_discount_percent / 100.0).round(2)
  end

  private

  def order_item_dropped?(attributes)
    attributes[:food_id].blank? && !ActiveModel::Type::Boolean.new.cast(attributes[:_destroy])
  end
end
