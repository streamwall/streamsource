require "rails_helper"

RSpec.describe StreamerAccount, type: :model do
  subject { build(:streamer_account) }

  describe "associations" do
    it { is_expected.to belong_to(:streamer) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:platform) }
    it { is_expected.to validate_presence_of(:username) }

    it "validates uniqueness of username per platform and streamer" do
      streamer = create(:streamer)
      create(:streamer_account, streamer: streamer, platform: "twitch", username: "testuser")

      duplicate = build(:streamer_account, streamer: streamer, platform: "twitch", username: "testuser")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:username]).to include("already exists for this platform")
    end

    it "allows same username on different platforms" do
      streamer = create(:streamer)
      create(:streamer_account, streamer: streamer, platform: "twitch", username: "testuser")

      different_platform = build(:streamer_account, streamer: streamer, platform: "youtube", username: "testuser")
      expect(different_platform).to be_valid
    end

    it "allows same username for different streamers" do
      create(:streamer_account, platform: "twitch", username: "testuser")

      different_streamer = build(:streamer_account, platform: "twitch", username: "testuser")
      expect(different_streamer).to be_valid
    end

    it "validates profile_url format when present" do
      account = build(:streamer_account, profile_url: "not-a-url")
      expect(account).not_to be_valid
      expect(account.errors[:profile_url]).to include("must be a valid URL starting with http:// or https://")
    end

    it "allows blank profile_url" do
      account = build(:streamer_account, profile_url: "")
      expect(account).to be_valid
    end

    it "validates platform inclusion" do
      account = build(:streamer_account)
      # Since Rails enums raise ArgumentError on invalid assignment, we need to test differently
      expect { account.platform = "invalid" }.to raise_error(ArgumentError, "'invalid' is not a valid platform")
    end
  end

  describe "enums" do
    it {
      expect(subject).to define_enum_for(:platform).with_values(
        tiktok: "TikTok",
        facebook: "Facebook",
        twitch: "Twitch",
        youtube: "YouTube",
        instagram: "Instagram",
        other: "Other",
      ).with_prefix(true).backed_by_column_of_type(:string)
    }
  end

  describe "scopes" do
    let!(:active_account) { create(:streamer_account, is_active: true) }
    let!(:inactive_account) { create(:streamer_account, is_active: false) }

    describe ".active" do
      it "returns only active accounts" do
        expect(described_class.active).to include(active_account)
        expect(described_class.active).not_to include(inactive_account)
      end
    end

    describe ".inactive" do
      it "returns only inactive accounts" do
        expect(described_class.inactive).to include(inactive_account)
        expect(described_class.inactive).not_to include(active_account)
      end
    end

    describe ".by_platform" do
      let!(:twitch_account) { create(:streamer_account, platform: "twitch") }
      let!(:youtube_account) { create(:streamer_account, platform: "youtube") }

      it "returns accounts for specific platform" do
        # The by_platform scope is checking against the stored value, not the key
        expect(described_class.by_platform("Twitch")).to include(twitch_account)
        expect(described_class.by_platform("Twitch")).not_to include(youtube_account)
      end
    end
  end

  describe "callbacks" do
    describe "#normalize_username" do
      it "strips whitespace and downcases username" do
        account = build(:streamer_account, username: "  TestUser  ")
        account.save!
        expect(account.username).to eq("testuser")
      end

      it "only normalizes when username changes" do
        account = create(:streamer_account, username: "TestUser")
        expect(account.username).to eq("testuser")

        # Updating other attributes should not re-normalize
        account.update!(profile_url: "https://example.com")
        expect(account.username).to eq("testuser")
      end
    end

    describe "#generate_profile_url" do
      it "generates TikTok profile URL" do
        # When we set platform: 'tiktok', Rails stores 'TikTok' in the DB
        account = build(:streamer_account, username: "testuser", profile_url: nil)
        account.platform = "tiktok"  # This will store 'TikTok' in the DB
        account.save!
        expect(account.profile_url).to eq("https://www.tiktok.com/@testuser")
      end

      it "generates Twitch profile URL" do
        account = build(:streamer_account, username: "testuser", profile_url: nil)
        account.platform = "twitch"  # This will store 'Twitch' in the DB
        account.save!
        expect(account.profile_url).to eq("https://www.twitch.tv/testuser")
      end

      it "generates Instagram profile URL" do
        account = build(:streamer_account, username: "testuser", profile_url: nil)
        account.platform = "instagram" # This will store 'Instagram' in the DB
        account.save!
        expect(account.profile_url).to eq("https://www.instagram.com/testuser/")
      end

      it "does not generate YouTube profile URL" do
        account = create(:streamer_account, platform: "youtube", username: "testuser", profile_url: nil)
        expect(account.profile_url).to be_nil
      end

      it "does not generate Facebook profile URL" do
        account = create(:streamer_account, platform: "facebook", username: "testuser", profile_url: nil)
        expect(account.profile_url).to be_nil
      end

      it "does not override existing profile URL" do
        account = create(:streamer_account, platform: "twitch", username: "testuser", profile_url: "https://custom.url")
        expect(account.profile_url).to eq("https://custom.url")
      end
    end
  end

  describe "instance methods" do
    let(:account) { create(:streamer_account, username: "TestUser", platform: "twitch") }

    describe "#display_name" do
      it "returns username with platform" do
        # The model returns the key, not the value
        expect(account.display_name).to eq("testuser (twitch)")
      end
    end

    describe "#deactivate!" do
      it "sets is_active to false" do
        account.is_active = true
        account.deactivate!
        expect(account.is_active).to be false
      end
    end

    describe "#activate!" do
      it "sets is_active to true" do
        account.is_active = false
        account.activate!
        expect(account.is_active).to be true
      end
    end
  end

  describe "database indexes" do
    it "has required indexes" do
      expect(ActiveRecord::Base.connection.index_exists?(:streamer_accounts, :streamer_id)).to be true
      expect(ActiveRecord::Base.connection.index_exists?(:streamer_accounts, :platform)).to be true
      expect(ActiveRecord::Base.connection.index_exists?(:streamer_accounts,
                                                         %i[streamer_id platform username])).to be true
    end
  end
end
