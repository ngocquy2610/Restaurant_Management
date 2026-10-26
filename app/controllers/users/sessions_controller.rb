class Users::SessionsController < Devise::SessionsController
  skip_before_action :verify_authenticity_token, if: :json_request?
  respond_to :json

  def create
    self.resource = warden.authenticate!(auth_options)
    sign_in(resource_name, resource, store: false)

    refresh_record, raw_refresh_token = RefreshToken.issue!(
      user: resource,
      user_agent: request.user_agent
    )

    cookies["restaurant_refresh"] = {
      value: raw_refresh_token,
      httponly: true,
      secure: Rails.env.production?,
      same_site: :lax,
      path: "/",
      expires: refresh_record.expires_at
    }

    respond_to do |format|
      format.html do
        redirect_to after_sign_in_path_for(resource), status: :see_other
      end
      format.json do
        render json: {
          status: "ok",
          user: user_payload(resource)
        }, status: :ok
      end
    end
  end

  def destroy
    raw_token = cookies["restaurant_refresh"]

    if raw_token.present?
      token = RefreshToken.find_by(
        token_hash: RefreshToken.digest(raw_token)
      )
      token&.revoke! if token&.active?
    end

    cookies.delete(
      "restaurant_refresh",
      path: "/",
      secure: Rails.env.production?,
      same_site: :lax,
      httponly: true
    )

    sign_out(resource_name)
    respond_to do |format|
      format.html do
        redirect_to root_path,
                    notice: "Logged out successfully.",
                    status: :see_other
      end
      format.json do
        render json: { status: "ok" }, status: :ok
      end
    end
  end

  private

  def user_payload(user)
    { id: user.id, email: user.email, full_name: user.full_name, role: user.role }
  end

  def json_request?
    request.format.json?
  end
end