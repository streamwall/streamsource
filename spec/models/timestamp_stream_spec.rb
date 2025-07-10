require "rails_helper"

RSpec.describe TimestampStream, type: :model do
  describe "timestamp formatting" do
    it "generates display format on save" do
      timestamp_stream = build(:timestamp_stream, stream_timestamp_seconds: 3665)
      timestamp_stream.save!
      expect(timestamp_stream.stream_timestamp_display).to eq("1:01:05")
    end

    it "does not generate if timestamp is nil" do
      timestamp_stream = build(:timestamp_stream, stream_timestamp_seconds: nil)
      timestamp_stream.save!
      expect(timestamp_stream.stream_timestamp_display).to be_nil
    end
  end

  describe "#formatted_stream_timestamp" do
    it "formats hours:minutes:seconds for long durations" do
      as = build(:timestamp_stream, stream_timestamp_seconds: 3665)
      expect(as.formatted_stream_timestamp).to eq("1:01:05")
    end

    it "formats minutes:seconds for short durations" do
      as = build(:timestamp_stream, stream_timestamp_seconds: 125)
      expect(as.formatted_stream_timestamp).to eq("2:05")
    end

    it "handles zero seconds" do
      as = build(:timestamp_stream, stream_timestamp_seconds: 0)
      expect(as.formatted_stream_timestamp).to eq("0:00")
    end

    it "returns saved display format if available" do
      as = build(:timestamp_stream, stream_timestamp_display: "Custom Format")
      expect(as.formatted_stream_timestamp).to eq("Custom Format")
    end

    it "returns Unknown for nil timestamp" do
      as = build(:timestamp_stream, stream_timestamp_seconds: nil)
      expect(as.formatted_stream_timestamp).to eq("Unknown")
    end
  end

  describe "#added_by?" do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let(:timestamp_stream) { create(:timestamp_stream, added_by_user: user) }

    it "returns true for the user who added it" do
      expect(timestamp_stream.added_by?(user)).to be true
    end

    it "returns false for other users" do
      expect(timestamp_stream.added_by?(other_user)).to be false
    end

    it "returns false for nil user" do
      expect(timestamp_stream.added_by?(nil)).to be false
    end
  end

  describe "uniqueness constraint" do
    it "prevents duplicate timestamp-stream pairs at database level" do
      timestamp = create(:timestamp)
      stream = create(:stream)
      user = create(:user)
      create(:timestamp_stream, timestamp: timestamp, stream: stream, added_by_user: user)

      duplicate = build(:timestamp_stream, timestamp: timestamp, stream: stream, added_by_user: user)
      expect(duplicate).to be_valid
      expect { duplicate.save! }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
