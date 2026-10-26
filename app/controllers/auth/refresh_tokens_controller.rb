module Auth
  class RefreshTokensController < ApplicationController
    skip_before_action :authenticate_user!, raise: false

    REFRESH_COOKIE = "restaurant_refresh"

    def create
      raw_token = cookies[REFRESH_COOKIE].presence || request.headers["X-Refresh-Token"].presence

      return render json: {error: "Refresh token is required"},
        status: :bad_request if raw_token.blank?

      digest = RefreshToken.digest(raw_token)
      current_token = RefreshToken.find_by(token_hash: digest)

      return render json: { error: "Invalid or expired refresh token" },
        status: :unauthorized unless current_token&.active?

      access_token, = Warden::JWTAuth::UserEncoder.new.call(
        current_token.user,
        :user,
        request.headers[Warden::JWTAuth.config.aud_header]
      )

      rotated = RefreshToken.rotate!(
        raw_token: raw_token,
        user_agent: request.user_agent
      )

      return render json: {error: "Invalid or expired refresh token"},
        status: :unauthorized unless rotated

      record, new_raw_token = rotated
      set_access_cookie(access_token)
      set_refresh_cookie(new_raw_token, record.expires_at)

      render json: {
        access_token: access_token,
        expires_in: Warden::JWTAuth.config.expiration_time
      }
    end

    private

    def set_refresh_cookie(value, expires_at)
      cookies[REFRESH_COOKIE] = {
        value: value,
        httponly: true,
        secure: Rails.env.production?,
        same_site: :lax,
        path: "/",
        expires: expires_at
      }
    end

    def set_access_cookie(value)
      cookies["restaurant_jwt"] = {
        value: value,
        httponly: true,
        secure: Rails.env.production?,
        same_site: :lax,
        path: "/",
        expires: Warden::JWTAuth.config.expiration_time.seconds.from_now
      }
    end

  end
end
