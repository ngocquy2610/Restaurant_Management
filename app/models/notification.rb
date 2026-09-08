class Notification < ApplicationRecord
  belongs_to :recipient, class_name: "User"

  enum :status, { unread: 0, read: 1 }, default: 0

  scope :recent, -> { order(created_at: :desc) }

  # Push every new notification to its recipient in real time via Action Cable.
  # Each notification bubbles up on the recipient's notification page
  # (#notifications-list) and lights up the bell badge (#notification-badge).
  after_create_commit :broadcast_new_notification

  private
    def broadcast_new_notification
      broadcast_prepend_to recipient, target: "notifications-list"
      broadcast_replace_to recipient,
        target: "notification-badge",
        partial: "notifications/bell_badge",
        locals: { user: recipient }
    end
end
