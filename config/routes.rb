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
  
  # Redirect root to API docs
  root to: redirect('/api-docs')
end