class HealthController < ApplicationController
  skip_before_action :authenticate_user!, if: -> { respond_to?(:authenticate_user!) }
  
  def index
    render json: {
      status: 'healthy',
      timestamp: Time.current.iso8601,
      version: Rails.application.config.version || '1.0.0'
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