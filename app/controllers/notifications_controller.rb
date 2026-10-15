class NotificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :filter_notifications, only: %i[index]

  # GET /notifications or /notifications.json
  def index
  end

  def mark_read
    current_user.notifications.find(params[:id]).read!
    head :no_content
  end

  def mark_all_read
    current_user.notifications.unread.update_all(status: :read)
    redirect_to notifications_path(q: params[:q], status: params[:status]), notice: "All notifications marked as read."
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def filter_notifications
      @query = params[:q].to_s.strip
      @status_filter = params[:status].presence_in(%w[unread read]) || "all"

      base = Notification.where(recipient_id: current_user.id)
      @unread_count = base.unread.count
      @read_count = base.read.count
      @total_count = base.count

      scope = base.search(@query)
      scope = scope.by_status(@status_filter) unless @status_filter == "all"
      @notifications = scope.recent.page(params[:page]).per(5)
    end

    def set_notifications
      @notification = Notification.find_by(params.expect(:id))
    end
end
