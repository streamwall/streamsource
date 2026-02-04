require "rails_helper"

RSpec.describe Stream, type: :model do
  let(:user) { create(:user) }

  describe "URL validation" do
    it "validates URL format" do
      stream = build(:stream, link: "not-a-url")
      expect(stream).not_to be_valid
      expect(stream.errors[:link]).to include("must be a valid HTTP or HTTPS URL")
    end

    it "accepts valid HTTPS URL" do
      stream = build(:stream, link: "https://example.com")
      expect(stream).to be_valid
    end

    it "accepts URLs with paths and query strings" do
      stream = build(:stream, link: "https://example.com/path?query=value&other=123")
      expect(stream).to be_valid
    end
  end

  describe "streamer assignment" do
    it "creates a streamer and account when none exists" do
      stream = create(:stream, user: user, streamer: nil, source: "TestStreamer", platform: "tiktok")

      expect(stream.streamer).to have_attributes(name: "TestStreamer", user: user)

      account = stream.streamer.streamer_accounts.find_by(platform: "tiktok")
      expect(account).to be_present
      expect(account.username).to eq("teststreamer")
    end

    it "reuses an existing streamer by platform account match" do
      streamer = create(:streamer, user: user, name: "Existing")
      create(:streamer_account, streamer: streamer, platform: "tiktok", username: "sameuser")

      stream = create(:stream, user: user, streamer: nil, source: "SameUser", platform: "tiktok")

      expect(stream.streamer).to eq(streamer)
    end

    it "reuses an existing streamer by name match" do
      streamer = create(:streamer, user: user, name: "NameMatch")

      stream = create(:stream, user: user, streamer: nil, source: "NameMatch", platform: "tiktok")

      expect(stream.streamer).to eq(streamer)
    end

    it "uses streamer_name when provided" do
      stream = build(:stream, user: user, streamer: nil, source: "sourceuser", platform: "tiktok")
      stream.streamer_name = "Display Name"

      stream.save!

      expect(stream.streamer).to be_present
      expect(stream.streamer.name).to eq("Display Name")
    end

    it "does not assign when stream has no user" do
      stream = build(:stream, user: nil, streamer: nil, source: "TestStreamer", platform: "tiktok")

      stream.assign_streamer_from_source

      expect(stream.streamer).to be_nil
    end
  end

  describe ".sorted" do
    it "orders by title when provided" do
      stream_a = create(:stream, title: "Alpha")
      stream_b = create(:stream, title: "Beta")

      expect(described_class.sorted("title", "asc").pluck(:id)).to eq([stream_a.id, stream_b.id])
    end

    it "falls back to default ordering for invalid columns" do
      unpinned = create(:stream, started_at: 2.hours.ago, is_pinned: false)
      pinned = create(:stream, :pinned, started_at: 1.hour.ago)

      expect(described_class.sorted("bogus", "asc").first).to eq(pinned)
      expect(described_class.sorted("bogus", "asc").second).to eq(unpinned)
    end
  end

  describe "instance methods" do
    let(:stream) { create(:stream, user: user) }

    describe "#pin!" do
      it "sets is_pinned to true" do
        expect { stream.pin! }.to change(stream, :is_pinned).from(false).to(true)
      end
    end

    describe "#toggle_pin!" do
      it "toggles is_pinned state" do
        expect { stream.toggle_pin! }.to change(stream, :is_pinned).from(false).to(true)
        expect { stream.toggle_pin! }.to change(stream, :is_pinned).from(true).to(false)
      end
    end

    describe "#mark_as_live!" do
      let(:offline_stream) { create(:stream, user: user, status: "Offline", started_at: nil) }

      it "updates status and timestamps" do
        offline_stream.mark_as_live!
        expect(offline_stream).to have_attributes(
          status: "live",
          last_checked_at: be_present,
          last_live_at: be_present,
          started_at: be_present,
        )
      end

      it "preserves existing started_at" do
        existing_start = 1.hour.ago
        stream_with_start = create(:stream, user: user, status: "Offline", started_at: existing_start)
        stream_with_start.mark_as_live!
        expect(stream_with_start.started_at).to be_within(1.second).of(existing_start)
      end
    end

    describe "#mark_as_offline!" do
      let(:live_stream) { create(:stream, user: user, status: "Live") }

      it "updates status to offline" do
        live_stream.mark_as_offline!
        expect(live_stream.status).to eq("offline")
        expect(live_stream.last_checked_at).to be_present
      end

      it "archives stream if should_archive? returns true" do
        allow(live_stream).to receive(:should_archive?).and_return(true)
        expect { live_stream.mark_as_offline! }.to change(live_stream, :is_archived).from(false).to(true)
      end
    end

    describe "#archive!" do
      it "sets is_archived to true" do
        expect { stream.archive! }.to change(stream, :is_archived).from(false).to(true)
      end

      it "sets ended_at if not already set" do
        stream.archive!
        expect(stream.ended_at).to be_present
      end

      it "preserves existing ended_at" do
        existing_end = 1.hour.ago
        stream.update!(ended_at: existing_end)
        stream.archive!
        expect(stream.ended_at).to be_within(1.second).of(existing_end)
      end
    end

    describe "#should_archive?" do
      it "returns false if already archived" do
        stream.update!(is_archived: true)
        expect(stream.should_archive?).to be false
      end

      it "returns false if live" do
        stream.update!(status: "Live")
        expect(stream.should_archive?).to be false
      end

      it "returns true if offline for more than 30 minutes" do
        stream.update!(status: "Offline")
        stream.update!(last_checked_at: 31.minutes.ago)
        expect(stream.should_archive?).to be true
      end
    end

    describe "#duration" do
      it "returns nil if started_at is nil" do
        stream.update!(started_at: nil)
        expect(stream.duration).to be_nil
      end

      it "calculates duration from started_at to ended_at" do
        stream.update!(started_at: 2.hours.ago, ended_at: 1.hour.ago)
        expect(stream.duration).to be_within(1).of(3600)
      end

      it "calculates duration from started_at to current time if not ended" do
        stream.update!(started_at: 1.hour.ago, ended_at: nil)
        expect(stream.duration).to be_within(10).of(3600)
      end
    end

    describe "#duration_in_words" do
      it "returns nil if duration is nil" do
        stream.update!(started_at: nil)
        expect(stream.duration_in_words).to be_nil
      end

      it "formats hours and minutes" do
        stream.update!(started_at: 2.hours.ago - 30.minutes, ended_at: Time.current)
        expect(stream.duration_in_words).to eq("2h 30m")
      end

      it "formats minutes only when less than an hour" do
        stream.update!(started_at: 45.minutes.ago, ended_at: Time.current)
        expect(stream.duration_in_words).to eq("45m")
      end
    end
  end
end
