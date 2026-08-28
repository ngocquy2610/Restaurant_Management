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
end
