class StreamSerializer < ActiveModel::Serializer
  attributes :id, :url, :name, :status, :is_pinned, :created_at, :updated_at
  
  belongs_to :user
end