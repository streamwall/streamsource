require "rails_helper"

RSpec.describe "Stream Location Integration", type: :request do
  let(:user) { create(:user) }
  let(:headers) { { "Authorization" => "Bearer #{JsonWebToken.encode(user_id: user.id)}" } }

  describe "POST /api/v1/streams with location" do
    let(:base_params) do
      {
        source: "Test Stream",
        link: "https://example.com/stream",
      }
    end

    context "when providing location object" do
      it "creates new location if it doesn't exist" do
        params = base_params.merge(
          location: {
            city: "Austin",
            state_province: "TX",
            country: "USA",
          },
        )

        expect do
          post "/api/v1/streams", params: params, headers: headers
        end.to change(Stream, :count).by(1)
                                     .and change(Location, :count).by(1)

        stream = Stream.last
        expect(stream.location).to be_present
        expect(stream.location.city).to eq("Austin")
        expect(stream.location.normalized_name).to eq("austin, tx, usa")
      end

      it "reuses existing location with same normalized name" do
        existing = create(:location, city: "New York", state_province: "NY", country: "USA")

        params = base_params.merge(
          location: {
            city: "NEW YORK", # Different case
            state_province: "ny", # Different case
            country: "USA",
          },
        )

        expect do
          post "/api/v1/streams", params: params, headers: headers
        end.to change(Stream, :count).by(1)
                                     .and change(Location, :count).by(0)

        stream = Stream.last
        expect(stream.location).to eq(existing)
      end

      it "creates location with coordinates" do
        params = base_params.merge(
          location: {
            city: "San Francisco",
            state_province: "CA",
            country: "USA",
            latitude: 37.7749,
            longitude: -122.4194,
          },
        )

        post "/api/v1/streams", params: params, headers: headers

        stream = Stream.last
        expect(stream.location.coordinates).to eq([37.7749, -122.4194])
      end
    end

    context "when providing location_id" do
      let(:location) { create(:location) }

      it "assigns existing location by id" do
        params = base_params.merge(location_id: location.id)

        post "/api/v1/streams", params: params, headers: headers

        stream = Stream.last
        expect(stream.location).to eq(location)
      end
    end

    context "when location is invalid" do
      it "still creates stream without location" do
        params = base_params.merge(
          location: {
            city: "", # Invalid - blank city
            state_province: "TX",
          },
        )

        expect do
          post "/api/v1/streams", params: params, headers: headers
        end.to change(Stream, :count).by(1)
                                     .and change(Location, :count).by(0)

        stream = Stream.last
        expect(stream.location).to be_nil
      end
    end
  end

  describe "PATCH /api/v1/streams/:id with location" do
    let(:stream) { create(:stream, user: user) }

    context "when adding location to stream without one" do
      it "creates and assigns new location" do
        params = {
          location: {
            city: "Seattle",
            state_province: "WA",
            country: "USA",
          },
        }

        expect do
          patch "/api/v1/streams/#{stream.id}", params: params, headers: headers
        end.to change(Location, :count).by(1)

        stream.reload
        expect(stream.location.city).to eq("Seattle")
      end
    end

    context "when updating stream with existing location" do
      let(:old_location) { create(:location, city: "Portland") }
      let(:stream) { create(:stream, user: user, location: old_location) }

      it "changes to different location" do
        new_location = create(:location, city: "Denver")

        patch "/api/v1/streams/#{stream.id}",
              params: { location_id: new_location.id },
              headers: headers

        stream.reload
        expect(stream.location).to eq(new_location)
      end

      it "removes location when set to null" do
        patch "/api/v1/streams/#{stream.id}",
              params: { location: nil },
              headers: headers

        stream.reload
        expect(stream.location).to be_nil
      end
    end
  end

  describe "GET /api/v1/streams with location data" do
    let!(:location) { create(:location, city: "Chicago", state_province: "IL") }
    let!(:stream_with_location) { create(:stream, location: location) }
    let!(:stream_without_location) { create(:stream, location: nil) }

    it "includes location data in response" do
      get "/api/v1/streams", headers: headers

      json = response.parsed_body
      stream_data = json["streams"].find { |s| s["id"] == stream_with_location.id }

      expect(stream_data["location"]).to be_present
      expect(stream_data["location"]["city"]).to eq("Chicago")
      expect(stream_data["location"]["display_name"]).to eq("Chicago, IL")
      expect(stream_data["location_id"]).to eq(location.id)
    end

    it "shows null location for streams without location" do
      get "/api/v1/streams", headers: headers

      json = response.parsed_body
      stream_data = json["streams"].find { |s| s["id"] == stream_without_location.id }

      expect(stream_data["location"]).to be_nil
      expect(stream_data["location_id"]).to be_nil
    end
  end

  describe "Stream filtering by location" do
    let!(:nyc_location) { create(:location, city: "New York", state_province: "NY") }
    let!(:la_location) { create(:location, city: "Los Angeles", state_province: "CA") }
    let!(:nyc_stream) { create(:stream, location: nyc_location) }
    let!(:la_stream) { create(:stream, location: la_location) }
    let!(:no_location_stream) { create(:stream, location: nil) }

    it "filters streams by location_id" do
      get "/api/v1/streams",
          params: { location_id: nyc_location.id },
          headers: headers

      json = response.parsed_body
      stream_ids = json["streams"].map { |s| s["id"] }

      expect(stream_ids).to include(nyc_stream.id)
      expect(stream_ids).not_to include(la_stream.id, no_location_stream.id)
    end

    it "searches streams by location city/state in search param" do
      get "/api/v1/streams",
          params: { search: "angeles" },
          headers: headers

      json = response.parsed_body
      stream_ids = json["streams"].map { |s| s["id"] }

      expect(stream_ids).to include(la_stream.id)
      expect(stream_ids).not_to include(nyc_stream.id)
    end
  end
end
