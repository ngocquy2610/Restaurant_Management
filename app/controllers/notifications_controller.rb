class NotificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :filter_notifications, only: %i[index]

  # GET /notifications or /notifications.json
  def index
  end

  def mark_read
    @notification = current_user.notifications.find(params[:id])
    @notification.read! if @notification.unread?

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace(
            helpers.dom_id(@notification),
            partial: "notifications/notification",
            locals: { notification: @notification }
          ),
          turbo_stream.replace(
            "notification-badge",
            partial: "notifications/bell_badge",
            locals: { user: current_user }
          ),
          turbo_stream.replace(
            "notifications-header-stats",
            partial: "notifications/header_stats",
            locals: {
              total_count: current_user.notifications.count,
              unread_count: current_user.notifications.unread.count,
              read_count: current_user.notifications.read.count,
              query: nil,
              status_filter: "all"
            }
          )
        ]
      end
      format.html { redirect_back fallback_location: notifications_path }
      format.json { head :no_content }
    end
  end

  def open
    @notification = current_user.notifications.find(params[:id])
    @notification.read! if @notification.unread?
    if @notification.redirect_url.present?
      redirect_to @notification.redirect_url, allow_other_host: true
    else
      redirect_to notifications_path
    end
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
