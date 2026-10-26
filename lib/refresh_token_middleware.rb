class RefreshTokenMiddleware
  COOKIE_NAME = "restaurant_jwt"

  ACCESS_TOKEN_TTL = 15.minutes.to_i

  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)
    token = request.cookie_jar.read(COOKIE_NAME)

    return @app.call(env) if token.blank?

    env["HTTP_AUTHORIZATION"] = "Bearer #{token}"

    status, headers, body = @app.call(env)

    [status, headers, body]
  end
end