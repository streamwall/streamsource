require "rails_helper"

RSpec.describe LocationSerializer do
  let(:location) { create(:location, :with_coordinates) }
  let(:serializer) { described_class.new(location) }
  let(:serialization) { ActiveModelSerializers::Adapter.create(serializer) }
  let(:json) { JSON.parse(serialization.to_json)["location"] || JSON.parse(serialization.to_json) }

  describe "attributes" do
    it "includes id" do
      expect(json["id"]).to eq(location.id)
    end

    it "includes city" do
      expect(json["city"]).to eq(location.city)
    end

    it "includes state_province" do
      expect(json["state_province"]).to eq(location.state_province)
    end

    it "includes region" do
      expect(json["region"]).to eq(location.region)
    end

    it "includes country" do
      expect(json["country"]).to eq(location.country)
    end

    it "includes display_name" do
      expect(json["display_name"]).to eq(location.display_name)
    end

    it "includes full_display_name" do
      expect(json["full_display_name"]).to eq(location.full_display_name)
    end

    it "includes normalized_name" do
      expect(json["normalized_name"]).to eq(location.normalized_name)
    end

    it "includes latitude" do
      expect(json["latitude"].to_f).to eq(location.latitude.to_f)
    end

    it "includes longitude" do
      expect(json["longitude"].to_f).to eq(location.longitude.to_f)
    end

    it "includes coordinates" do
      if location.coordinates
        expect(json["coordinates"]).to eq([location.latitude.to_s, location.longitude.to_s])
      else
        expect(json["coordinates"]).to be_nil
      end
    end

    it "includes streams_count" do
      expect(json["streams_count"]).to eq(location.streams.count)
    end

    it "includes created_at" do
      expect(json["created_at"]).to be_present
    end

    it "includes updated_at" do
      expect(json["updated_at"]).to be_present
    end
  end

  describe "with nil coordinates" do
    let(:location) { create(:location, latitude: nil, longitude: nil) }

    it "returns nil for coordinates" do
      expect(json["coordinates"]).to be_nil
    end

    it "returns nil for latitude" do
      expect(json["latitude"]).to be_nil
    end

    it "returns nil for longitude" do
      expect(json["longitude"]).to be_nil
    end
  end

  describe "with associated streams" do
    before do
      user = create(:user)
      # Create streams without city/state since they conflict with location
      3.times do
        create(:stream, user: user, location: location, city: nil, state: nil)
      end
    end

    it "includes correct streams_count" do
      location.reload
      expect(json["streams_count"]).to eq(3)
    end
  end

  describe "collection serialization" do
    let(:locations) { create_list(:location, 3) }
    let(:serializer) { ActiveModel::Serializer::CollectionSerializer.new(locations, serializer: described_class) }

    it "serializes multiple locations" do
      # Handle both array and wrapped responses
      locations_data = json.is_a?(Array) ? json : json["locations"]
      expect(locations_data).to be_an(Array)
      expect(locations_data.size).to eq(3)
    end

    it "includes all attributes for each location" do
      # Handle both array and wrapped responses
      locations_data = json.is_a?(Array) ? json : json.values.first
      locations_data.each do |location_json|
        expect(location_json).to include(
          "id", "city", "state_province", "country",
          "display_name", "normalized_name", "streams_count"
        )
      end
    end
  end

  describe "custom attributes" do
    it "uses display_name method from model" do
      location = create(:location, city: "Austin", state_province: "TX")
      serializer = described_class.new(location)
      result = JSON.parse(ActiveModelSerializers::Adapter.create(serializer).to_json)
      # Handle wrapped response
      location_data = result["location"] || result

      expect(location_data["display_name"]).to eq("Austin, TX")
    end

    it "uses full_display_name method from model" do
      location = create(:location, city: "Austin", state_province: "TX", country: "USA")
      serializer = described_class.new(location)
      result = JSON.parse(ActiveModelSerializers::Adapter.create(serializer).to_json)
      # Handle wrapped response
      location_data = result["location"] || result

      expect(location_data["full_display_name"]).to eq("Austin, TX, USA")
    end
  end
end
