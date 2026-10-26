class JwtCookieBridge
  COOKIE_NAME = "restaurant_jwt"
  TOKEN_LIFETIME = 900

  def initialize(app)
    @app = app
  end

  def call(env)
    method = env["REQUEST_METHOD"]
    path = env["PATH_INFO"]

    cookies = Rack::Utils.parse_cookies_header(env["HTTP_COOKIE"].to_s)
    # Take out the "HTTP_COOKIE" from header of HTTP Request object
    # Rack: interface to communicate between Web Server (Puma) and Web Framework (Rails)
    # Utils: a Rack's module which include helpers functions

    token = cookies[COOKIE_NAME]

    if token.present? && env["HTTP_AUTHORIZATION"].blank?
      env["HTTP_AUTHORIZATION"] = "Bearer #{token}"
    end

    status, headers, body = @app.call(env)
    # take status, headers, body from response of @app

    if method == "POST" && path == "/login" && status.between?(200,399)
      set_login_cookie(headers)
    elsif method == "DELETE" && path == "/logout" && status.between?(200, 399)
      clear_login_cookie(headers)
    elsif status == 401 && token.present?
      clear_login_cookie(headers)
      headers["Session-Expired"] = "true"
    end

    [status, headers, body]
  end

  private

  def set_login_cookie(headers)
    authorization = headers["Authorization"] || headers["authorization"]
    return unless authorization&.start_with?("Bearer ")

    token = authorization.delete_prefix("Bearer ")
    append_cookie(
      headers,
      "#{COOKIE_NAME}=#{token}; Path=/; HttpOnly; SameSite=Lax; Max-Age=#{TOKEN_LIFETIME}"
    )
    # HttpOnly - block js to read cookie
    # SameSite = Lax - CSRF prevent

  end

  def clear_login_cookie(headers)
    append_cookie(
      headers,
      "#{COOKIE_NAME}=; Path=/; HttpOnly; SameSite=Lax; Max-Age=0"
    )
  end

  def append_cookie(headers, cookie)
    cookie += "; Secure" if Rails.env.production?
    headers["Set-Cookie"] = Array(headers["Set-Cookie"]) + [cookie]
  end
end