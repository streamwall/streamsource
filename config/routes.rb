Rails.application.routes.draw do
  # Mount ActionCable
  mount ActionCable.server => '/cable'
  
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
  
  # Admin routes  
  namespace :admin do
    get 'login', to: 'sessions#new'
    post 'login', to: 'sessions#create'
    delete 'logout', to: 'sessions#destroy'
    
    # Define streamers routes with new and edit
    get 'streamers/new', to: 'streamers#new', as: 'new_streamer'
    get 'streamers/:id/edit', to: 'streamers#edit', as: 'edit_streamer'
    resources :streamers
    
    # Define streams routes with new and edit
    get 'streams/new', to: 'streams#new', as: 'new_stream'
    get 'streams/:id/edit', to: 'streams#edit', as: 'edit_stream'
    patch 'streams/:id/toggle_pin', to: 'streams#toggle_pin', as: 'toggle_pin_stream'
    resources :streams, only: [:index, :show, :create, :update, :destroy]
    
    # Define users routes with new and edit
    get 'users/new', to: 'users#new', as: 'new_user'
    get 'users/:id/edit', to: 'users#edit', as: 'edit_user'
    patch 'users/:id/toggle_admin', to: 'users#toggle_admin', as: 'toggle_admin_user'
    resources :users, only: [:index, :show, :create, :update, :destroy]
    
    resources :feature_flags, only: [:index] do
      member do
        patch :update
      end
    end
    
    # Timestamps routes
    resources :timestamps, only: [:index, :show, :new, :edit, :create, :update, :destroy] do
      member do
        patch 'resolve'
        patch 'dismiss'
        post 'add_stream'
      end
    end
    
    root to: 'streams#index'
  end
  
  # Mount Flipper UI without authentication - we'll handle it via Rack middleware
  mount Flipper::UI.app(Flipper) => '/admin/flipper'
  
  # Redirect root to API docs
  root to: redirect('/api-docs')
end