class Notification < ApplicationRecord
  belongs_to :recipient, class_name: "User"

  enum :status, { unread: 0, read: 1 }, default: 0

  scope :recent, -> { order(created_at: :desc) }

  after_create_commit :broadcast_new_notification

  private
    def broadcast_new_notification
      broadcast_prepend_to recipient, target: "notifications-list" # helper của Turbo Streams
      broadcast_replace_to recipient,
        target: "notification-badge",
        partial: "notifications/bell_badge",
        locals: { user: recipient }
    end
end
