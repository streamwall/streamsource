require "rails_helper"

RSpec.describe "Api::V1::Locations", type: :request do
  let(:user) { create(:user) }
  let(:headers) { { "Authorization" => "Bearer #{JsonWebToken.encode(user_id: user.id)}" } }

  describe "GET /api/v1/locations" do
    let!(:locations) { create_list(:location, 3) }

    context "when authenticated" do
      it "returns paginated locations" do
        get "/api/v1/locations", headers: headers

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json["locations"].size).to eq(3)
        expect(json["meta"]).to include("current_page", "total_pages", "total_count")
      end

      it "filters by search query" do
        nyc = create(:location, city: "New York", state_province: "NY")
        create(:location, city: "Los Angeles", state_province: "CA")

        get "/api/v1/locations", params: { search: "york" }, headers: headers

        json = response.parsed_body
        expect(json["locations"].size).to eq(1)
        expect(json["locations"][0]["id"]).to eq(nyc.id)
      end

      it "filters by country" do
        usa = create(:location, country: "USA")
        uk = create(:location, country: "UK")

        get "/api/v1/locations", params: { country: "USA" }, headers: headers

        json = response.parsed_body
        location_ids = json["locations"].map { |l| l["id"] }
        expect(location_ids).to include(usa.id)
        expect(location_ids).not_to include(uk.id)
      end

      it "filters by state" do
        ca = create(:location, state_province: "CA")
        ny = create(:location, state_province: "NY")

        get "/api/v1/locations", params: { state: "CA" }, headers: headers

        json = response.parsed_body
        location_ids = json["locations"].map { |l| l["id"] }
        expect(location_ids).to include(ca.id)
        expect(location_ids).not_to include(ny.id)
      end
    end

    context "when not authenticated" do
      it "returns unauthorized" do
        get "/api/v1/locations"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /api/v1/locations/all" do
    let!(:locations) { create_list(:location, 50) }

    it "returns all locations without pagination" do
      get "/api/v1/locations/all", headers: headers

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["locations"].size).to eq(50)
      expect(json["locations"][0]).to include(
        "id", "city", "state_province", "country", "display_name", "normalized_name"
      )
    end

    it "sets cache headers" do
      get "/api/v1/locations/all", headers: headers

      expect(response.headers["Cache-Control"]).to include("public")
      expect(response.headers["Cache-Control"]).to include("max-age=300")
    end
  end

  describe "GET /api/v1/locations/:id" do
    let(:location) { create(:location, :with_coordinates) }

    it "returns the location" do
      get "/api/v1/locations/#{location.id}", headers: headers

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["id"]).to eq(location.id)
      expect(json["city"]).to eq(location.city)
      expect(json["coordinates"]).to eq([location.latitude.to_f, location.longitude.to_f])
      expect(json).to include("streams_count")
    end

    it "returns 404 for non-existent location" do
      get "/api/v1/locations/999999", headers: headers

      expect(response).to have_http_status(:not_found)
      json = response.parsed_body
      expect(json["error"]).to eq("Location not found")
    end
  end

  describe "POST /api/v1/locations" do
    let(:valid_params) do
      {
        location: {
          city: "San Francisco",
          state_province: "CA",
          country: "USA",
          latitude: 37.7749,
          longitude: -122.4194,
        },
      }
    end

    context "with valid params" do
      it "creates a new location" do
        expect do
          post "/api/v1/locations", params: valid_params, headers: headers
        end.to change(Location, :count).by(1)

        expect(response).to have_http_status(:created)
        json = response.parsed_body
        expect(json["city"]).to eq("San Francisco")
        expect(json["normalized_name"]).to eq("san francisco, ca, usa")
      end
    end

    context "with invalid params" do
      it "returns validation errors" do
        invalid_params = { location: { city: "" } }

        post "/api/v1/locations", params: invalid_params, headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
        json = response.parsed_body
        expect(json["error"]).to eq("Validation failed")
        expect(json["details"]["city"]).to include("can't be blank")
      end

      it "prevents duplicate normalized names" do
        create(:location, city: "New York", state_province: "NY")
        duplicate_params = { location: { city: "New York", state_province: "NY" } }

        post "/api/v1/locations", params: duplicate_params, headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
        json = response.parsed_body
        expect(json["details"]["normalized_name"]).to include("has already been taken")
      end
    end
  end

  describe "PATCH /api/v1/locations/:id" do
    let(:location) { create(:location) }
    let(:update_params) do
      {
        location: {
          state_province: "CA",
          latitude: 34.0522,
          longitude: -118.2437,
        },
      }
    end

    it "updates the location" do
      patch "/api/v1/locations/#{location.id}", params: update_params, headers: headers

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["state_province"]).to eq("CA")
      expect(json["latitude"]).to eq("34.0522")

      location.reload
      expect(location.state_province).to eq("CA")
    end

    it "updates normalized name when city/state/country change" do
      update_params = { location: { city: "Los Angeles" } }

      patch "/api/v1/locations/#{location.id}", params: update_params, headers: headers

      location.reload
      expect(location.normalized_name).to include("los angeles")
    end
  end

  describe "DELETE /api/v1/locations/:id" do
    let!(:location) { create(:location) }

    context "when location has no streams" do
      it "deletes the location" do
        expect do
          delete "/api/v1/locations/#{location.id}", headers: headers
        end.to change(Location, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end
    end

    context "when location has streams" do
      let!(:stream) { create(:stream, location: location) }

      it "prevents deletion" do
        expect do
          delete "/api/v1/locations/#{location.id}", headers: headers
        end.not_to change(Location, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        json = response.parsed_body
        expect(json["error"]).to eq("Cannot delete location")
        expect(json["details"]["base"]).to include(/being used by 1 stream/)
      end
    end
  end
end
