class AdminFlipperAuth
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)
    
    # Only protect Flipper UI routes
    if request.path.start_with?('/admin/flipper')
      session = env['rack.session']
      user_id = session[:admin_user_id]
      
      unless user_id && User.find_by(id: user_id)&.admin?
        # Redirect to admin login
        return [302, {'Location' => '/admin/login', 'Content-Type' => 'text/html'}, []]
      end
    end
    
    @app.call(env)
  end
end