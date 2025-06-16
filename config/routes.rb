Rails.application.routes.draw do
  # API routes
  namespace :api do
    namespace :v1 do
      # Authentication
      devise_for :users, skip: [:registrations, :sessions, :passwords]
      post 'users/signup', to: 'users#signup'
      post 'users/login', to: 'users#login'
      
      # Streams
      resources :streams do
        member do
          put 'pin'
          delete 'pin', to: 'streams#unpin'
          get 'analytics'
        end
        
        collection do
          post 'bulk_import'
          get 'export'
        end
      end
    end
  end
  
  # Health checks
  get 'health', to: 'health#index'
  get 'health/live', to: 'health#live'
  get 'health/ready', to: 'health#ready'
  
  # Prometheus metrics
  get 'metrics', to: 'metrics#index'
  
  # API Documentation
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/swagger'
  
  # Feature flags admin UI (admin only)
  authenticate :user, ->(u) { u.admin? } do
    mount Flipper::UI.app(Flipper) => '/admin/flipper'
  end
  
  # Alternative: Use a custom constraint for non-Devise authentication
  constraints lambda { |request| 
    token = request.headers['Authorization']&.split(' ')&.last
    if token
      begin
        payload = JWT.decode(token, Rails.application.secret_key_base, true, algorithm: ApplicationConstants::JWT::ALGORITHM)[0]
        user = User.find_by(id: payload['user_id'])
        user&.admin?
      rescue
        false
      end
    else
      false
    end
  } do
    mount Flipper::UI.app(Flipper) => '/flipper'
  end
  
  # Redirect root to API docs
  root to: redirect('/api-docs')
end