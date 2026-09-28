class PreorderReleaseJob < ApplicationJob
  queue_as :default
  retry_on ActiveRecord::Deadlocked, attempts: 3, wait: 5.seconds
  discard_on ActiveJob::DeserializationError

  def perform(order_id)
    order = Order.find_by(id: order_id)
    return unless order
    return if order.released_to_kitchen_at.present? || !order.preorder?
    return unless order.reservation && Reservation::ACTIVE_STATUSES.include?(order.reservation.status.to_sym)
    return unless order.due_for_release?
    return unless order.release_to_kitchen!
    User.where(role: :kitchen_staff).find_each do |u|
      Notification.create!(
        recipient: u,
        title: "Pre-order",
        body: "#{order.reservation.guest_name} (Table #{order.table&.table_number}, Meal start at #{order.reservation.slot_start.strftime('%H:%M')})."
      )
    end
  end
end
