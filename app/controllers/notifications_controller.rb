class NotificationsController < ApplicationController
  before_action :filter_notifications, only: %i[index]
  # before_action :set_notification, only: %i[show]

  # GET /notifications or /notifications.json
  def index
  end

  def mark_all_read
    current_user.notifications.unread.update_all(status: :read)
    redirect_to notifications_path
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def filter_notifications
      @notifications = Notification.where(recipient_id: current_user.id).recent
    end

    def set_notifications
      @notification = Notification.find_by(params.expect(:id))
    end
end
