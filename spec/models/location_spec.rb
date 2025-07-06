require "rails_helper"

RSpec.describe Location, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:streams).dependent(:nullify) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:city) }
    it { is_expected.to validate_presence_of(:normalized_name) }

    describe "uniqueness of normalized_name" do
      subject { create(:location) }

      it { is_expected.to validate_uniqueness_of(:normalized_name) }
    end
  end

  describe "callbacks" do
    describe "#set_normalized_name" do
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
  end

  describe "scopes" do
    let!(:usa_location) { create(:location, city: "New York", state_province: "NY", country: "USA") }
    let!(:uk_location) { create(:location, city: "London", country: "UK") }
    let!(:canada_location) { create(:location, city: "Toronto", state_province: "ON", country: "Canada") }

    describe ".ordered" do
      it "orders by city and state_province" do
        expect(described_class.ordered).to eq([uk_location, usa_location, canada_location])
      end
    end

    describe ".by_country" do
      it "filters by country" do
        expect(described_class.by_country("USA")).to include(usa_location)
        expect(described_class.by_country("USA")).not_to include(uk_location, canada_location)
      end

      it "returns all when country is blank" do
        expect(described_class.by_country("")).to contain_exactly(usa_location, uk_location, canada_location)
      end
    end

    describe ".by_state" do
      it "filters by state_province" do
        expect(described_class.by_state("NY")).to include(usa_location)
        expect(described_class.by_state("NY")).not_to include(uk_location, canada_location)
      end
    end

    describe ".search" do
      it "searches in city" do
        expect(described_class.search("york")).to include(usa_location)
        expect(described_class.search("london")).to include(uk_location)
      end

      it "searches in state_province" do
        expect(described_class.search("NY")).to include(usa_location)
        expect(described_class.search("ON")).to include(canada_location)
      end

      it "searches in country" do
        expect(described_class.search("USA")).to include(usa_location)
        expect(described_class.search("canada")).to include(canada_location)
      end

      it "is case insensitive" do
        expect(described_class.search("NEW YORK")).to include(usa_location)
        expect(described_class.search("usa")).to include(usa_location)
      end

      it "returns all when query is blank" do
        expect(described_class.search("")).to contain_exactly(usa_location, uk_location, canada_location)
      end
    end
  end

  describe ".find_or_create_from_params" do
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
      end
    end

    context "when city is blank" do
      it "returns nil" do
        params = { city: "", state_province: "CA" }
        expect(described_class.find_or_create_from_params(params)).to be_nil
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
      location = build(:location, city: "Unknown City")
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
      location = build(:location, city: "Lagos", region: "West Africa", country: "Nigeria")
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
