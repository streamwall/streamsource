# StreamSource Rails Migration Plan

## Executive Summary

Migrating StreamSource from Node.js/Express/Prisma to Ruby on Rails would significantly simplify the codebase while maintaining all functionality. Rails' "convention over configuration" philosophy and mature ecosystem would eliminate much of the boilerplate code currently needed.

## Why Rails Makes Sense for StreamSource

### Current Pain Points in Node.js:
1. **Fragmented ecosystem** - Separate packages for ORM, validation, authentication, etc.
2. **Boilerplate code** - Manual setup for security, validation, error handling
3. **Type safety complexity** - TypeScript adds overhead for a relatively simple CRUD API
4. **Testing complexity** - Extensive mocking required for Prisma and authentication

### Rails Advantages:
1. **Integrated stack** - ActiveRecord, validations, security, and testing built-in
2. **API-only mode** - Lightweight Rails API without views since Rails 5
3. **Convention over configuration** - Less code, more functionality
4. **Mature patterns** - Battle-tested approaches for authentication, authorization
5. **Developer productivity** - Faster to add features and maintain

## Architecture Comparison

### Current Stack (Node.js)
```
Express 5 + TypeScript
├── Prisma ORM (database)
├── Passport.js (authentication)
├── express-validator (validation)
├── accesscontrol (authorization)
├── Helmet + rate-limit (security)
├── Winston (logging)
├── Jest (testing)
└── Docker (deployment)
```

### Proposed Rails Stack
```
Rails 7.2 (API mode)
├── ActiveRecord (built-in ORM)
├── Devise or JWT gem (authentication)
├── Built-in validations
├── Pundit or CanCanCan (authorization)  
├── Rack::Attack (rate limiting)
├── Built-in logger
├── RSpec (testing)
└── Docker (deployment)
```

## Database Schema Translation

### Prisma Schema → Rails Migration

**Users Table**
```ruby
class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.string :email, null: false, index: { unique: true }
      t.string :password_digest, null: false
      t.string :role, default: 'default'
      t.timestamps
    end
  end
end
```

**Streams Table**
```ruby
class CreateStreams < ActiveRecord::Migration[7.2]
  def change
    create_table :streams do |t|
      t.string :source
      t.string :platform
      t.string :link, null: false
      t.string :status, default: 'submitted'
      t.string :title
      t.boolean :is_expired, default: false
      t.datetime :checked_at
      t.datetime :live_at
      t.string :embed_link
      t.string :posted_by
      t.boolean :is_pinned, default: false
      t.string :city
      t.string :region
      t.timestamps
    end

    add_index :streams, :link, unique: true
    add_index :streams, :status
    add_index :streams, :is_expired
    add_index :streams, :is_pinned
  end
end
```

## Model Translation

### User Model
```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_secure_password
  
  # Validations (replacing express-validator)
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, format: {
    with: /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/,
    message: "must include lowercase, uppercase, and number"
  }, on: :create
  validates :role, inclusion: { in: %w[default editor admin] }
  
  # Scopes
  scope :editors, -> { where(role: 'editor') }
  scope :admins, -> { where(role: 'admin') }
  
  # Role checks
  def editor?
    role == 'editor'
  end
  
  def admin?
    role == 'admin'
  end
  
  def can_modify_streams?
    editor? || admin?
  end
end
```

### Stream Model
```ruby
# app/models/stream.rb
class Stream < ApplicationRecord
  # Validations
  validates :link, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[submitted live offline] }
  
  # Callbacks (replacing Prisma extensions)
  before_validation :normalize_link
  before_create :infer_location
  
  # Scopes (much cleaner than Prisma where clauses)
  scope :active, -> { where(is_expired: false) }
  scope :pinned, -> { where(is_pinned: true) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_platform, ->(platform) { where(platform: platform) }
  scope :search, ->(query) { where("title ILIKE ? OR source ILIKE ?", "%#{query}%", "%#{query}%") }
  
  # Business logic
  def pin!
    update!(is_pinned: true)
  end
  
  def unpin!
    update!(is_pinned: false)
  end
  
  def can_modify?
    !is_pinned?
  end
  
  private
  
  def normalize_link
    return unless link.present?
    self.link = link.strip.downcase.sub(/\/$/, '').sub(/https?:\/\/(www\.)?/, '')
  end
  
  def infer_location
    return if city.present? || region.present?
    
    past_stream = Stream.where(link: link)
                       .or(Stream.where(source: source))
                       .where.not(city: nil)
                       .or(Stream.where.not(region: nil))
                       .order(created_at: :desc)
                       .first
                       
    if past_stream
      self.city ||= past_stream.city
      self.region ||= past_stream.region
    end
  end
end
```

## Controller Translation

### ApplicationController
```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods
  
  before_action :authenticate_user!, except: [:index, :show]
  
  private
  
  def authenticate_user!
    authenticate_or_request_with_http_token do |token|
      jwt_payload = JWT.decode(token, Rails.application.credentials.secret_key_base).first
      @current_user = User.find(jwt_payload['user_id'])
    rescue JWT::ExpiredSignature
      render json: { error: 'Token expired' }, status: :unauthorized
    rescue
      render json: { error: 'Invalid token' }, status: :unauthorized
    end
  end
  
  def current_user
    @current_user
  end
end
```

### StreamsController
```ruby
# app/controllers/api/v1/streams_controller.rb
class Api::V1::StreamsController < ApplicationController
  before_action :set_stream, only: [:show, :update, :destroy, :pin, :unpin]
  before_action :authorize_modification!, only: [:create, :update, :destroy, :pin, :unpin]
  
  # GET /api/v1/streams
  def index
    @streams = Stream.active
    
    # Filtering (much cleaner than Express route)
    @streams = @streams.by_status(params[:status]) if params[:status]
    @streams = @streams.by_platform(params[:platform]) if params[:platform]
    @streams = @streams.search(params[:q]) if params[:q]
    @streams = @streams.where(is_pinned: params[:is_pinned]) if params.key?(:is_pinned)
    
    # Date filtering
    @streams = @streams.where(created_at: params[:created_at_from]..) if params[:created_at_from]
    @streams = @streams.where(created_at: ..params[:created_at_to]) if params[:created_at_to]
    
    # Sorting
    order_by = params[:order_by] || 'created_at'
    order_dir = params[:order_dir] || 'desc'
    @streams = @streams.order(order_by => order_dir)
    
    # Response format
    if params[:format] == 'array'
      render json: @streams
    else
      render json: { streams: @streams, count: @streams.count }
    end
  end
  
  # GET /api/v1/streams/:id
  def show
    render json: { stream: @stream }
  end
  
  # POST /api/v1/streams
  def create
    @stream = Stream.new(stream_params)
    
    if @stream.save
      render json: { stream: @stream }, status: :created
    else
      render json: { errors: @stream.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  # PATCH /api/v1/streams/:id
  def update
    unless @stream.can_modify?
      return render json: { error: 'Cannot update a pinned stream' }, status: :forbidden
    end
    
    if @stream.update(stream_params)
      render json: { stream: @stream }
    else
      render json: { errors: @stream.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  # DELETE /api/v1/streams/:id
  def destroy
    unless @stream.can_modify?
      return render json: { error: 'Cannot delete a pinned stream' }, status: :forbidden
    end
    
    @stream.destroy
    head :no_content
  end
  
  # PUT /api/v1/streams/:id/pin
  def pin
    @stream.pin!
    render json: { stream: @stream }
  end
  
  # DELETE /api/v1/streams/:id/pin
  def unpin
    @stream.unpin!
    render json: { stream: @stream }
  end
  
  private
  
  def set_stream
    @stream = Stream.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Stream not found' }, status: :not_found
  end
  
  def stream_params
    params.require(:stream).permit(:source, :platform, :link, :status, :title, 
                                   :embed_link, :posted_by, :city, :region)
  end
  
  def authorize_modification!
    unless current_user&.can_modify_streams?
      render json: { error: 'Forbidden' }, status: :forbidden
    end
  end
end
```

### UsersController
```ruby
# app/controllers/api/v1/users_controller.rb
class Api::V1::UsersController < ApplicationController
  skip_before_action :authenticate_user!, only: [:create, :login]
  
  # POST /api/v1/users/signup
  def create
    @user = User.new(user_params)
    
    if @user.save
      render json: { message: 'Signed up successfully', user: user_json(@user) }
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  # POST /api/v1/users/login
  def login
    @user = User.find_by(email: params[:email])
    
    if @user&.authenticate(params[:password])
      token = generate_token(@user)
      render json: { token: token }
    else
      render json: { error: 'Invalid credentials' }, status: :unauthorized
    end
  end
  
  private
  
  def user_params
    params.permit(:email, :password, :role)
  end
  
  def user_json(user)
    user.as_json(only: [:id, :email, :role, :created_at, :updated_at])
  end
  
  def generate_token(user)
    JWT.encode(
      { user_id: user.id, email: user.email, exp: 24.hours.from_now.to_i },
      Rails.application.credentials.secret_key_base,
      'HS256'
    )
  end
end
```

## Routes (config/routes.rb)
```ruby
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :streams do
        member do
          put :pin
          delete :pin, action: :unpin
        end
      end
      
      post 'users/signup', to: 'users#create'
      post 'users/login', to: 'users#login'
    end
  end
  
  # Health checks
  get '/health', to: 'health#index'
  get '/health/live', to: 'health#live'
  get '/health/ready', to: 'health#ready'
  
  # Metrics
  get '/metrics', to: 'metrics#index'
end
```

## Testing Strategy

### RSpec Tests (Much Cleaner!)
```ruby
# spec/models/stream_spec.rb
RSpec.describe Stream, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:link) }
    it { should validate_uniqueness_of(:link) }
    it { should validate_inclusion_of(:status).in_array(%w[submitted live offline]) }
  end
  
  describe 'callbacks' do
    it 'normalizes link before validation' do
      stream = Stream.new(link: 'HTTPS://WWW.EXAMPLE.COM/PATH/')
      stream.valid?
      expect(stream.link).to eq('example.com/path')
    end
    
    it 'infers location from past streams' do
      create(:stream, link: 'example.com/stream', city: 'Boston', region: 'MA')
      new_stream = create(:stream, link: 'example.com/stream')
      expect(new_stream.city).to eq('Boston')
      expect(new_stream.region).to eq('MA')
    end
  end
  
  describe 'scopes' do
    it 'returns only active streams' do
      active = create(:stream, is_expired: false)
      expired = create(:stream, is_expired: true)
      expect(Stream.active).to include(active)
      expect(Stream.active).not_to include(expired)
    end
  end
end

# spec/requests/streams_spec.rb
RSpec.describe 'Streams API', type: :request do
  let(:user) { create(:user, role: 'editor') }
  let(:token) { generate_token(user) }
  let(:headers) { { 'Authorization' => "Bearer #{token}" } }
  
  describe 'GET /api/v1/streams' do
    it 'returns all active streams' do
      active_streams = create_list(:stream, 3, is_expired: false)
      expired_stream = create(:stream, is_expired: true)
      
      get '/api/v1/streams'
      
      expect(response).to have_http_status(:ok)
      expect(json_response['count']).to eq(3)
    end
    
    it 'filters by status' do
      live_stream = create(:stream, status: 'live')
      offline_stream = create(:stream, status: 'offline')
      
      get '/api/v1/streams', params: { status: 'live' }
      
      expect(json_response['streams'].length).to eq(1)
      expect(json_response['streams'][0]['id']).to eq(live_stream.id)
    end
  end
  
  describe 'POST /api/v1/streams' do
    it 'creates a stream for authorized users' do
      stream_params = { stream: { link: 'example.com/new', status: 'live' } }
      
      post '/api/v1/streams', params: stream_params, headers: headers
      
      expect(response).to have_http_status(:created)
      expect(Stream.last.link).to eq('example.com/new')
    end
    
    it 'rejects creation for unauthorized users' do
      post '/api/v1/streams', params: { stream: { link: 'example.com' } }
      
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
```

## Security & Middleware

### Rack::Attack Configuration
```ruby
# config/initializers/rack_attack.rb
Rack::Attack.throttle('api/ip', limit: 100, period: 15.minutes) do |req|
  req.ip if req.path.start_with?('/api')
end

Rack::Attack.throttle('auth/ip', limit: 5, period: 15.minutes) do |req|
  req.ip if req.path.include?('login') || req.path.include?('signup')
end
```

### CORS Configuration
```ruby
# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'
    resource '/api/*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      expose: ['Authorization']
  end
end
```

## Deployment

### Dockerfile (Much Simpler!)
```dockerfile
FROM ruby:3.3-alpine

RUN apk add --no-cache \
    postgresql-dev \
    build-base \
    nodejs \
    yarn \
    tzdata

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3

COPY . .

# Precompile assets (even in API mode for error pages)
RUN bundle exec rails assets:precompile

EXPOSE 3000

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
```

## Migration Steps

### Phase 1: Rails Setup & Models
1. Initialize Rails API: `rails new streamsource-rails --api --database=postgresql`
2. Create models with migrations
3. Set up validations and callbacks
4. Configure database

### Phase 2: Authentication & Authorization
1. Add JWT gem or Devise-JWT
2. Implement user authentication
3. Add Pundit for authorization policies
4. Set up role-based access

### Phase 3: API Endpoints
1. Create controllers
2. Set up routes with proper namespacing
3. Add request specs
4. Implement filtering and sorting

### Phase 4: Production Features
1. Add Rack::Attack for rate limiting
2. Configure CORS
3. Set up logging with Lograge
4. Add APM (AppSignal or New Relic)
5. Configure Docker

### Phase 5: Testing & Documentation
1. Complete RSpec test suite
2. Add API documentation (Swagger/OpenAPI)
3. Set up CI/CD with GitHub Actions
4. Performance testing

## Benefits Summary

### Code Reduction
- **Current**: ~3,000 lines of TypeScript/JavaScript
- **Rails**: ~1,000 lines of Ruby (estimated 66% reduction)

### Dependencies
- **Current**: 40+ npm packages
- **Rails**: ~15 gems (much more integrated)

### Development Speed
- New features: 3-4x faster to implement
- Testing: Built-in factories and fixtures
- Debugging: Better error messages and stack traces

### Maintainability
- Convention over configuration
- Consistent patterns across the codebase
- Excellent documentation and community

## Conclusion

While the current Node.js/TypeScript/Prisma stack is modern and functional, Rails would provide:
1. **Significantly less code** to maintain
2. **Faster feature development**
3. **More integrated tooling**
4. **Better conventions** for API development
5. **Simpler testing** with less mocking

The migration would take approximately 2-3 weeks for a single developer, but would result in a much more maintainable codebase that follows established patterns rather than assembling various npm packages.