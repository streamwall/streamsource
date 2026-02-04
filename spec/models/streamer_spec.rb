require "rails_helper"

RSpec.describe Streamer, type: :model do
  describe "name uniqueness validation" do
    it "validates uniqueness of name" do
      create(:streamer, name: "TestStreamer")
      duplicate = build(:streamer, name: "TestStreamer")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include("has already been taken")
    end

    it "validates uniqueness case-insensitively" do
      create(:streamer, name: "TestStreamer")
      duplicate = build(:streamer, name: "teststreamer")
      expect(duplicate).not_to be_valid
    end
  end

  describe "name normalization" do
    it "strips whitespace from name" do
      streamer = build(:streamer, name: "  TestStreamer  ")
      streamer.save
      expect(streamer.name).to eq("TestStreamer")
    end
  end

  describe "posted_by callback" do
    it "sets posted_by to user email if not provided" do
      user = create(:user, email: "test@example.com")
      streamer = create(:streamer, user: user, posted_by: nil)
      expect(streamer.posted_by).to eq("test@example.com")
    end

    it "does not override existing posted_by" do
      streamer = create(:streamer, posted_by: "custom@example.com")
      expect(streamer.posted_by).to eq("custom@example.com")
    end
  end

  describe "instance methods" do
    let(:user) { create(:user) }
    let(:streamer) { create(:streamer, user: user) }

    describe "#active_stream" do
      it "returns the most recent live non-archived stream" do
        create(:stream, streamer: streamer, status: "live", started_at: 2.hours.ago)
        recent_live = create(:stream, streamer: streamer, status: "live", started_at: 1.hour.ago)
        create(:stream, streamer: streamer, status: "live", is_archived: true)

        expect(streamer.active_stream).to eq(recent_live)
      end

      it "returns nil when no active streams" do
        create(:stream, streamer: streamer, status: "offline")
        expect(streamer.active_stream).to be_nil
      end
    end

    describe "#platforms" do
      it "returns unique platform names for active accounts" do
        create(:streamer_account, streamer: streamer, platform: "twitch", is_active: true)
        create(:streamer_account, streamer: streamer, platform: "youtube", is_active: true)
        create(:streamer_account, streamer: streamer, platform: "twitch", username: "alt_account", is_active: true)
        create(:streamer_account, streamer: streamer, platform: "facebook", is_active: false)

        expect(streamer.platforms).to contain_exactly("twitch", "youtube")
      end

      it "returns empty array when no active accounts" do
        expect(streamer.platforms).to eq([])
      end
    end

    describe "#create_or_continue_stream!" do
      it "creates a new stream when no recent stream exists" do
        expect do
          streamer.create_or_continue_stream!(link: "https://twitch.tv/test", source: "twitch")
        end.to change { streamer.streams.count }.by(1)

        stream = streamer.streams.last
        expect(stream).to have_attributes(
          status: "live",
          last_checked_at: be_present,
          last_live_at: be_present,
        )
      end

      it "continues existing stream if checked recently" do
        existing = create(:stream,
                          streamer: streamer,
                          last_checked_at: 15.minutes.ago,
                          is_archived: false)

        expect do
          streamer.create_or_continue_stream!(link: "https://twitch.tv/test", source: "twitch")
        end.not_to(change { streamer.streams.count })

        existing.reload
        expect(existing.status).to eq("live")
        expect(existing.last_checked_at).to be > 1.minute.ago
      end

      it "creates new stream if existing stream is old" do
        existing = create(:stream,
                          streamer: streamer,
                          user: user,
                          is_archived: false,
                          status: "offline")

        existing.update!(last_checked_at: 2.hours.ago)
        existing.reload

        expect(existing.last_checked_at).to be < 30.minutes.ago
        expect(existing.streamer).to eq(streamer)

        expect do
          streamer.create_or_continue_stream!(link: "https://twitch.tv/test", source: "twitch")
        end.to change { streamer.streams.count }.by(1)
      end
    end
  end

  describe ".resolve_for_stream" do
    let(:user) { create(:user) }

    it "returns nil when stream has no user" do
      stream = build(:stream, user: nil, source: "TestStreamer", platform: "tiktok")

      expect(described_class.resolve_for_stream(stream)).to be_nil
    end

    it "returns nil when name is blank" do
      stream = build(:stream, user: user, source: " ", platform: "tiktok")

      expect(described_class.resolve_for_stream(stream)).to be_nil
    end

    it "reuses streamer by platform account match" do
      streamer = create(:streamer, user: user, name: "Existing")
      create(:streamer_account, streamer: streamer, platform: "tiktok", username: "teststreamer")
      stream = build(:stream, user: user, source: "TestStreamer", platform: "tiktok")

      expect(described_class.resolve_for_stream(stream)).to eq(streamer)
    end

    it "reuses streamer by name match" do
      streamer = create(:streamer, user: user, name: "Name Match")
      stream = build(:stream, user: user, source: "Name Match", platform: "tiktok")

      expect(described_class.resolve_for_stream(stream)).to eq(streamer)
    end

    it "creates streamer using candidate name and ensures account" do
      stream = build(:stream, user: user, source: "SourceUser", platform: "tiktok")

      resolved = described_class.resolve_for_stream(stream, candidate_name: "Display Name")

      expect(resolved).to have_attributes(name: "Display Name", user: user)
      account = resolved.streamer_accounts.find_by(platform: "tiktok")
      expect(account).to be_present
      expect(account.username).to eq("sourceuser")
    end
  end

  describe "#ensure_account" do
    let(:streamer) { create(:streamer) }

    it "creates a normalized account when missing" do
      expect do
        streamer.ensure_account(platform: "tiktok", source: "  TestUser  ")
      end.to change(StreamerAccount, :count).by(1)

      account = streamer.streamer_accounts.find_by(platform: "tiktok")
      expect(account.username).to eq("testuser")
    end

    it "does not create duplicate accounts" do
      create(:streamer_account, streamer: streamer, platform: "tiktok", username: "testuser")

      expect do
        streamer.ensure_account(platform: "tiktok", source: "TestUser")
      end.not_to change(StreamerAccount, :count)
    end

    it "skips unsupported platforms" do
      expect do
        streamer.ensure_account(platform: "unknown", source: "TestUser")
      end.not_to change(StreamerAccount, :count)
    end
  end
end
