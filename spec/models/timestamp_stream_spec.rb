require "rails_helper"

RSpec.describe TimestampStream, type: :model do
  subject { build(:timestamp_stream) }

  describe "associations" do
    it { is_expected.to belong_to(:timestamp) }
    it { is_expected.to belong_to(:stream) }
    it { is_expected.to belong_to(:added_by_user).class_name("User") }
  end

  describe "validations" do
    it { is_expected.to validate_numericality_of(:stream_timestamp_seconds).is_greater_than_or_equal_to(0).allow_nil }
  end

  describe "scopes" do
    let!(:user) { create(:user) }
    let!(:timestamp) { create(:timestamp, user: user) }
    let!(:stream) { create(:stream) }
    let!(:with_timestamp) do
      create(:timestamp_stream, timestamp: timestamp, stream: create(:stream), stream_timestamp_seconds: 120)
    end
    let!(:without_timestamp) do
      create(:timestamp_stream, timestamp: timestamp, stream: create(:stream), stream_timestamp_seconds: nil)
    end

    describe ".with_timestamp" do
      it "returns only timestamps with timestamps" do
        expect(described_class.with_timestamp).to include(with_timestamp)
        expect(described_class.with_timestamp).not_to include(without_timestamp)
      end
    end
  end

  describe "callbacks" do
    describe "#generate_timestamp_display" do
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
  end

  describe "instance methods" do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let(:timestamp_stream) { create(:timestamp_stream, added_by_user: user) }

    describe "#added_by?" do
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
  end

  describe "uniqueness constraint" do
    it "prevents duplicate timestamp-stream pairs at database level" do
      timestamp = create(:timestamp)
      stream = create(:stream)
      user = create(:user)
      create(:timestamp_stream, timestamp: timestamp, stream: stream, added_by_user: user)

      duplicate = build(:timestamp_stream, timestamp: timestamp, stream: stream, added_by_user: user)
      # No model validation exists for uniqueness, only database constraint
      expect(duplicate).to be_valid
      expect { duplicate.save! }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "database indexes" do
    it "has required indexes" do
      expect(ActiveRecord::Base.connection.index_exists?(:timestamp_streams, %i[timestamp_id stream_id])).to be true
      expect(ActiveRecord::Base.connection.index_exists?(:timestamp_streams, :stream_id)).to be true
      expect(ActiveRecord::Base.connection.index_exists?(:timestamp_streams, :stream_timestamp_seconds)).to be true
    end
  end
end
