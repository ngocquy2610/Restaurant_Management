class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :authenticate_user!

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
  def after_sign_in_path_for(resource)
    case resource.role
    when 'admin' then root_path
    else customer_home_path
    end
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:full_name, :phone, :location])
    devise_parameter_sanitizer.permit(:account_update, keys: [:full_name, :phone, :location, :avatar_url])
  end
end
