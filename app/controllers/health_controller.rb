class HealthController < ApplicationController
  # Health endpoints don't need authentication
  
  def index
    render json: {
      status: ApplicationConstants::Messages::HEALTH_HEALTHY,
      timestamp: Time.current.iso8601,
      version: ApplicationConstants::App::VERSION
    }
  end
  
  def live
    render json: { status: ApplicationConstants::Messages::HEALTH_OK }
  end
  
  def ready
    # Check database connection
    ActiveRecord::Base.connection.execute(ApplicationConstants::Database::HEALTH_CHECK_QUERY)
    
    render json: {
      status: ApplicationConstants::Messages::HEALTH_READY,
      database: ApplicationConstants::Messages::DATABASE_CONNECTED
    }
  rescue => e
    render json: {
      status: ApplicationConstants::Messages::HEALTH_NOT_READY,
      error: e.message
    }, status: :service_unavailable
  end
end