class LocationSerializer < ActiveModel::Serializer
  attributes :id, :city, :state_province, :region, :country,
             :display_name, :full_display_name, :normalized_name,
             :latitude, :longitude, :coordinates, :created_at, :updated_at

  attribute :streams_count

  def streams_count
    object.streams.count
  end

  delegate :coordinates, to: :object
end
