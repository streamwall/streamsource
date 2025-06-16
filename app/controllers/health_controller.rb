class HealthController < ApplicationController
  # Health endpoints don't need authentication
  
  def index
    render json: {
      status: 'healthy',
      timestamp: Time.current.iso8601,
      version: '1.0.0'
    }
  end
  
  def live
    render json: { status: 'ok' }
  end
  
  def ready
    # Check database connection
    ActiveRecord::Base.connection.execute('SELECT 1')
    
    render json: {
      status: 'ready',
      database: 'connected'
    }
  rescue => e
    render json: {
      status: 'not ready',
      error: e.message
    }, status: :service_unavailable
  end
end