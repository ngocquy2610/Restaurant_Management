class Notification < ApplicationRecord
  belongs_to :recipient, class_name: "User"

  enum :status, { unread: 0, read: 1 }, default: 0

  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) if status.present? && statuses.key?(status.to_s) }
  scope :search, ->(term) {
    if term.present?
      pattern = "%#{sanitize_sql_like(term.to_s.strip)}%"
      where("notifications.title ILIKE :t OR notifications.body ILIKE :t", t: pattern)
    end
  }
  # URL or path pointing to the page this notification relates to.
  # Null means the notification has no associated page.
  validates :redirect_url,
    allow_blank: true,
    format: {
      with: %r{\A(?:(?:https?|ftp)://|/)[^\s]*\z},
      message: "must be a valid URL (e.g. https://example.com/orders/5) or a path (e.g. /orders/5)"
    }

  after_create_commit :broadcast_new_notification

  def self.notify_role(role, title:, body: nil, redirect_url: nil, exclude: nil)
    User.where(role: role).where.not(id: exclude&.id).find_each do |user|
      create!(recipient: user, title: title, body: body, redirect_url: redirect_url)
    end
  end

  private
    def broadcast_new_notification
      broadcast_prepend_to recipient, target: "notifications-list" # helper của Turbo Streams
      Turbo::StreamsChannel.broadcast_action_to recipient,
        action: :toast,
        attributes: { "notification-id": id, title: title, body: body.to_s, url: redirect_url.to_s }
      broadcast_replace_to recipient,
        target: "notification-badge",
        partial: "notifications/bell_badge",
        locals: { user: recipient }
    end
end
