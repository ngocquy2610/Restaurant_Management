class PreorderReleaseSweepJob < ApplicationJob
  queue_as :low

  def perform
    Order.unreleased_preorders.joins(:reservation)
      .includes(:reservation, :table, :order_items)
      .find_each(batch_size: 200) do |order|
        PreorderReleaseJob.perform_later(order.id) if order.due_for_release?
      end
  end
end
