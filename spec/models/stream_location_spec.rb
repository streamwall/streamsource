require "rails_helper"

RSpec.describe "Stream Location Integration", type: :model do
  let(:user) { create(:user) }
  let(:valid_attributes) do
    {
      link: "https://twitch.tv/test",
      source: "Test Stream",
      user: user,
    }
  end

  describe "location creation from city/state" do
    context "when location validation is disabled" do
      before { Flipper.disable(:location_validation) }

      it "creates location from city and state" do
        stream = Stream.create!(
          valid_attributes.merge(
            city: "Austin",
            state: "TX",
          ),
        )

        expect(stream.location).to be_present
        expect(stream.location.city).to eq("Austin")
        expect(stream.location.state_province).to eq("TX")
        expect(stream.location.is_known_city).to be(false)
      end

      it "reuses existing location" do
        # Create first stream with location
        stream1 = Stream.create!(
          valid_attributes.merge(
            city: "Austin",
            state: "TX",
          ),
        )

        # Create second stream with same location
        stream2 = Stream.create!(
          valid_attributes.merge(
            link: "https://twitch.tv/test2",
            source: "Test Stream 2",
            city: "Austin",
            state: "TX",
          ),
        )

        expect(stream1.location).to eq(stream2.location)
        expect(Location.where(city: "Austin", state_province: "TX").count).to eq(1)
      end

      it "handles nil city gracefully" do
        stream = Stream.create!(
          valid_attributes.merge(
            city: nil,
            state: "TX",
          ),
        )

        expect(stream.location).to be_nil
      end

      it "handles blank city gracefully" do
        stream = Stream.create!(
          valid_attributes.merge(
            city: "",
            state: "TX",
          ),
        )

        expect(stream.location).to be_nil
      end
    end

    context "when location validation is enabled" do
      before do
        allow(Flipper).to receive(:enabled?).with(ApplicationConstants::Features::LOCATION_VALIDATION).and_return(true)
      end

      context "with known cities" do
        before do
          create(:location, :known_city, city: "Austin", state_province: "TX")
          create(:location, :known_city, city: "Dallas", state_province: "TX")
        end

        it "accepts known city" do
          stream = Stream.create!(
            valid_attributes.merge(
              city: "Austin",
              state: "TX",
            ),
          )

          expect(stream.location).to be_present
          expect(stream.location.city).to eq("Austin")
          expect(stream.location.is_known_city).to be(true)
        end

        it "rejects unknown city" do
          stream = Stream.new(
            valid_attributes.merge(
              city: "Unknown City",
              state: "XX",
            ),
          )

          expect(stream).not_to be_valid
          expect(stream.errors[:city]).to include("is not a recognized city. Please contact an admin to add it.")
        end

        it "handles case-insensitive matching" do
          stream = Stream.create!(
            valid_attributes.merge(
              city: "AUSTIN",
              state: "tx",
            ),
          )

          expect(stream.location).to be_present
          expect(stream.location.city).to eq("Austin")
        end

        it "prevents save when city is invalid" do
          stream = Stream.new(valid_attributes.merge(city: "InvalidCity", state: "XX"))

          expect(stream.save).to be(false)
          expect(stream).to be_new_record
          expect(stream.errors[:city]).to be_present
        end
      end
    end
  end

  describe "updating location" do
    let(:stream) { create(:stream, user: user) }

    before { Flipper.disable(:location_validation) }

    it "can update location" do
      stream.update!(city: "Dallas", state: "TX")

      expect(stream.location).to be_present
      expect(stream.location.city).to eq("Dallas")
      expect(stream.location.state_province).to eq("TX")
    end

    it "preserves location when updating other attributes" do
      stream.update!(city: "Austin", state: "TX")
      original_location = stream.location

      stream.update!(source: "Updated Source")

      expect(stream.location).to eq(original_location)
    end
  end

  describe "#display_location" do
    it "shows location name when present" do
      location = create(:location, city: "Austin", state_province: "TX")
      stream = create(:stream, location: location, user: user, city: "Austin", state: "TX")

      expect(stream.display_location).to eq("Austin, TX")
    end

    it "falls back to city/state when no location" do
      stream = Stream.new(city: "Austin", state: "TX")
      expect(stream.display_location).to eq("Austin, TX")
    end

    it "handles partial data" do
      stream = Stream.new(city: "Austin")
      expect(stream.display_location).to eq("Austin")
    end

    it "returns empty string when no location data" do
      stream = Stream.new
      expect(stream.display_location).to eq("")
    end
  end

  describe "city and state preservation" do
    it "preserves city and state separately from location" do
      stream = Stream.create!(
        valid_attributes.merge(
          city: "Austin",
          state: "TX",
        ),
      )

      expect(stream.city).to eq("Austin")
      expect(stream.state).to eq("TX")
      expect(stream.location).to be_present
    end
  end

  describe "callbacks and initialization" do
    it "processes pending location on initialization" do
      stream = Stream.new(valid_attributes.merge(city: "Austin", state: "TX"))

      # The pending values should be set
      expect(stream.instance_variable_get(:@pending_city)).to eq("Austin")
      expect(stream.instance_variable_get(:@pending_state)).to eq("TX")
    end

    it "creates location before validation" do
      Flipper.disable(:location_validation)

      stream = Stream.new(valid_attributes.merge(city: "Austin", state: "TX"))
      stream.valid?

      expect(stream.location).to be_present
      expect(stream.location).to be_persisted
    end
  end
end
