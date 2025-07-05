class StreamSerializer < ActiveModel::Serializer
  attributes :id, :source, :link, :status, :is_pinned, :created_at, :updated_at,
             :city, :state, :platform, :notes, :title, :last_checked_at, 
             :last_live_at, :posted_by, :orientation, :kind, :location_id
  
  belongs_to :user
  belongs_to :location
  
  # Conditionally show analytics URL if feature is enabled
  attribute :analytics_url, if: :show_analytics?
  
  # Conditionally show tags if feature is enabled
  attribute :tags, if: :show_tags?
  
  def show_analytics?
    Flipper.enabled?(ApplicationConstants::Features::STREAM_ANALYTICS, current_user)
  end
  
  def show_tags?
    Flipper.enabled?(ApplicationConstants::Features::STREAM_TAGS, current_user)
  end
  
  def analytics_url
    "/api/v1/streams/#{object.id}/analytics"
  end
  
  def tags
    # Placeholder - would come from a tags association
    []
  end
  
  def current_user
    # Access current user from serialization scope
    scope&.current_user if scope&.respond_to?(:current_user)
  end
end