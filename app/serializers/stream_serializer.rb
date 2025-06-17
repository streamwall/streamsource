class StreamSerializer < ActiveModel::Serializer
  attributes :id, :url, :name, :status, :is_pinned, :created_at, :updated_at
  
  belongs_to :user
  
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
    @instance_options[:scope]&.current_user
  end
end