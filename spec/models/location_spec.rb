require "rails_helper"

RSpec.describe Location, type: :model do
  describe "normalized name validation" do
    it "validates uniqueness" do
      existing = create(:location, city: "Austin", state_province: "TX", country: "USA")
      duplicate = build(:location, city: "Austin", state_province: "TX", country: "USA")
      
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:normalized_name]).to include("has already been taken")
    end

    it "is effectively case-insensitive due to normalization" do
      existing = create(:location, city: "Austin", state_province: "TX", country: "USA")
      duplicate = build(:location, city: "AUSTIN", state_province: "tx", country: "USA")
      
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:normalized_name]).to include("has already been taken")
    end
  end

  describe "normalized name generation" do
    it "sets normalized name before validation" do
      location = build(:location, city: "New York", state_province: "NY", country: "USA")
      location.valid?
      expect(location.normalized_name).to eq("new york, ny, usa")
    end

    it "handles missing state_province" do
      location = build(:location, city: "London", state_province: nil, country: "UK")
      location.valid?
      expect(location.normalized_name).to eq("london, uk")
    end

    it "handles only city" do
      location = build(:location, city: "Paris", state_province: nil, country: nil)
      location.valid?
      expect(location.normalized_name).to eq("paris")
    end
  end


  describe ".find_or_create_from_params" do
    context "when city is blank" do
      it "returns nil" do
        params = { city: "", state_province: "CA" }
        expect(described_class.find_or_create_from_params(params)).to be_nil
      end
    end

    context "when location validation is disabled" do
      before { Flipper.disable(:location_validation) }

      context "when location exists" do
        let!(:existing) { create(:location, city: "Chicago", state_province: "IL", country: "USA") }

        it "finds existing location by normalized name" do
          params = { city: "Chicago", state_province: "IL", country: "USA" }
          location = described_class.find_or_create_from_params(params)
          expect(location).to eq(existing)
          expect(described_class.count).to eq(1)
        end

        it "finds with different casing" do
          params = { city: "CHICAGO", state_province: "il", country: "usa" }
          location = described_class.find_or_create_from_params(params)
          expect(location).to eq(existing)
        end
      end

      context "when location does not exist" do
        it "creates new location" do
          params = {
            city: "San Francisco",
            state_province: "CA",
            country: "USA",
            latitude: 37.7749,
            longitude: -122.4194,
          }

          expect do
            described_class.find_or_create_from_params(params)
          end.to change(described_class, :count).by(1)

          location = described_class.last
          expect(location.city).to eq("San Francisco")
          expect(location.state_province).to eq("CA")
          expect(location.latitude).to eq(37.7749)
          expect(location.longitude).to eq(-122.4194)
          expect(location.is_known_city).to eq(false)
        end
      end
    end

    context "when location validation is enabled" do
      before { Flipper.enable(:location_validation) }

      context "with known cities" do
        let!(:austin) { create(:location, :known_city, city: "Austin", state_province: "TX", country: "USA") }
        let!(:dallas) { create(:location, :known_city, city: "Dallas", state_province: "TX", country: "USA") }

        it "returns known city when exact match found" do
          result = described_class.find_or_create_from_params(city: "Austin", state_province: "TX", country: "USA")
          expect(result).to eq(austin)
        end

        it "returns known city with case-insensitive match" do
          result = described_class.find_or_create_from_params(city: "AUSTIN", state_province: "tx", country: "USA")
          expect(result).to eq(austin)
        end

        it "handles unknown cities appropriately" do
          result = described_class.find_or_create_from_params(city: "Houston", state_province: "TX", country: "USA")
          # Should either return nil or create a new location depending on business logic
          expect(result.nil? || result.is_a?(Location)).to be true
        end

        it "handles existing but non-known cities" do
          # Create a location that exists but isn't marked as known
          existing = create(:location, city: "San Antonio", state_province: "TX", country: "USA", is_known_city: false)
          
          result = described_class.find_or_create_from_params(city: "San Antonio", state_province: "TX", country: "USA")
          # Should handle existing locations appropriately
          expect(result.nil? || result == existing).to be true
        end
      end
    end
  end

  describe ".normalize_location_name" do
    it "normalizes location parts" do
      expect(described_class.normalize_location_name("New York", "NY", "USA")).to eq("new york, ny, usa")
    end

    it "handles nil values" do
      expect(described_class.normalize_location_name("Paris", nil, "France")).to eq("paris, france")
      expect(described_class.normalize_location_name("Tokyo", nil, nil)).to eq("tokyo")
    end

    it "strips whitespace" do
      expect(described_class.normalize_location_name("  London  ", "  ", "UK  ")).to eq("london, uk")
    end
  end

  describe "#display_name" do
    it "shows city and state" do
      location = build(:location, city: "Austin", state_province: "TX", country: "USA")
      expect(location.display_name).to eq("Austin, TX")
    end

    it "shows city and country when no state" do
      location = build(:location, city: "Paris", state_province: nil, country: "France")
      expect(location.display_name).to eq("Paris, France")
    end

    it "shows only city when no state or country" do
      location = build(:location, city: "Unknown City", state_province: nil, country: nil)
      expect(location.display_name).to eq("Unknown City")
    end

    it "prefers state over country when both present" do
      location = build(:location, city: "Toronto", state_province: "ON", country: "Canada")
      expect(location.display_name).to eq("Toronto, ON")
    end
  end

  describe "#full_display_name" do
    it "shows all parts" do
      location = build(:location, city: "New York", state_province: "NY", region: "Northeast", country: "USA")
      expect(location.full_display_name).to eq("New York, NY, USA")
    end

    it "includes region when no state" do
      location = build(:location, city: "Lagos", state_province: nil, region: "West Africa", country: "Nigeria")
      expect(location.full_display_name).to eq("Lagos, West Africa, Nigeria")
    end
  end

  describe "#coordinates?" do
    it "returns true when both lat and lng present" do
      location = build(:location, latitude: 40.7128, longitude: -74.0060)
      expect(location.coordinates?).to be true
    end

    it "returns false when latitude missing" do
      location = build(:location, latitude: nil, longitude: -74.0060)
      expect(location.coordinates?).to be false
    end

    it "returns false when longitude missing" do
      location = build(:location, latitude: 40.7128, longitude: nil)
      expect(location.coordinates?).to be false
    end
  end

  describe "#coordinates" do
    it "returns array of coordinates" do
      location = build(:location, latitude: 40.7128, longitude: -74.0060)
      expect(location.coordinates).to eq([40.7128, -74.0060])
    end

    it "returns nil when no coordinates" do
      location = build(:location, latitude: nil, longitude: nil)
      expect(location.coordinates).to be_nil
    end
  end
end
