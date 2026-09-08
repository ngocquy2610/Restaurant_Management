class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  layout :layout_by_resource
  include Pundit

  allow_browser versions: :modern

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  stale_when_importmap_changes
  def after_sign_in_path_for(resource)
    case resource.role
    when 'admin' then root_path
    else root_path
    end
  end

  protected

  def user_not_authorized
    respond_to do |format|
      format.html { render file: Rails.root.join("public/403.html"), status: :forbidden, layout: false }
      format.json { render json: { error: "You are not authorized to perform this action." }, status: :forbidden }
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:full_name, :phone, :location])
    devise_parameter_sanitizer.permit(:account_update, keys: [:full_name, :phone, :location, :avatar])
  end

  def layout_by_resource
    devise_controller? ? "application" : "application"
  end

  private

  def notify_user(recipient:, title:, body: nil)
    Notification.create!(recipient: recipient, title: title, body: body)
    # Example how to use:
    # notify_user(
    #   recipient: @reservation.customer,
    #   title: "Reservation confirmed",
    #   body: "Your table for #{@reservation.reservation_time.strftime('%H:%M %d/%m')} is confirmed — Table #{@table.table_number}."
    # )
  end

  def notify_role(role, title:, body: nil, exclude: nil)
    User.where(role: role).where.not(id: exclude&.id).find_each do |user|
      Notification.create!(recipient: user, title: title, body: body)
    end
    # Example how to use:
    # notify_role(:receptionist,
    #   title: "New reservation request",
    #   body: "#{@reservation.customer&.name || @reservation.guest_name} requested a table for #{@reservation.party_size} at #{@reservation.reservation_time.strftime('%H:%M %d/%m')}."
    # )
  end
end
