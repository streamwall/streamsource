# Rack middleware to guard Flipper UI access.
class AdminFlipperAuth
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)

    # Only protect Flipper UI routes
    if request.path.start_with?("/admin/flipper")
      begin
        user = current_user(env)

        unless user&.admin?
          # Return 403 Forbidden instead of redirect for consistency with tests
          return [403, { "Content-Type" => "text/plain" }, ["Forbidden"]]
        end
      rescue StandardError
        # Return 403 Forbidden if current_user raises an error
        return [403, { "Content-Type" => "text/plain" }, ["Forbidden"]]
      end
    end

    @app.call(env)
  end

  private

  def current_user(env)
    session = env["rack.session"]
    return nil unless session

    user_id = session[:user_id] || session[:admin_user_id]
    return nil unless user_id

    if defined?(@current_user)
      @current_user
    else
      @current_user = User.find_by(id: user_id)
    end
  rescue StandardError
    nil
  end
end
