require 'rails_helper'

RSpec.describe StreamerAccount, type: :model do
  subject { build(:streamer_account) }
  
  describe 'associations' do
    it { should belong_to(:streamer) }
  end
  
  describe 'validations' do
    it { should validate_presence_of(:platform) }
    it { should validate_presence_of(:username) }
    it { should validate_length_of(:username).is_at_least(1).is_at_most(100) }
    it { should validate_length_of(:profile_url).is_at_most(500) }
    
    it 'validates uniqueness of username per platform and streamer' do
      streamer = create(:streamer)
      create(:streamer_account, streamer: streamer, platform: 'twitch', username: 'testuser')
      
      duplicate = build(:streamer_account, streamer: streamer, platform: 'twitch', username: 'testuser')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:username]).to include('has already been taken')
    end
    
    it 'allows same username on different platforms' do
      streamer = create(:streamer)
      create(:streamer_account, streamer: streamer, platform: 'twitch', username: 'testuser')
      
      different_platform = build(:streamer_account, streamer: streamer, platform: 'youtube', username: 'testuser')
      expect(different_platform).to be_valid
    end
    
    it 'allows same username for different streamers' do
      create(:streamer_account, platform: 'twitch', username: 'testuser')
      
      different_streamer = build(:streamer_account, platform: 'twitch', username: 'testuser')
      expect(different_streamer).to be_valid
    end
    
    it 'validates profile_url format when present' do
      account = build(:streamer_account, profile_url: 'not-a-url')
      expect(account).not_to be_valid
      expect(account.errors[:profile_url]).to include('must be a valid URL')
    end
    
    it 'allows blank profile_url' do
      account = build(:streamer_account, profile_url: '')
      expect(account).to be_valid
    end
  end
  
  describe 'enums' do
    it { should define_enum_for(:platform).with_values(
      twitch: 'twitch',
      youtube: 'youtube',
      tiktok: 'tiktok',
      instagram: 'instagram',
      facebook: 'facebook',
      kick: 'kick',
      rumble: 'rumble',
      other: 'other'
    ).with_prefix(true) }
    
    it { should define_enum_for(:status).with_values(
      active: 'active',
      suspended: 'suspended',
      deleted: 'deleted',
      inactive: 'inactive'
    ).with_prefix(true) }
  end
  
  describe 'scopes' do
    let!(:active_account) { create(:streamer_account, status: 'active', is_verified: true) }
    let!(:suspended_account) { create(:streamer_account, status: 'suspended') }
    let!(:unverified_account) { create(:streamer_account, status: 'active', is_verified: false) }
    
    describe '.active' do
      it 'returns only active accounts' do
        expect(StreamerAccount.active).to contain_exactly(active_account, unverified_account)
      end
    end
    
    describe '.verified' do
      it 'returns only verified accounts' do
        expect(StreamerAccount.verified).to contain_exactly(active_account)
      end
    end
    
    describe '.by_platform' do
      let!(:twitch_account) { create(:streamer_account, platform: 'twitch') }
      let!(:youtube_account) { create(:streamer_account, platform: 'youtube') }
      
      it 'returns accounts for specific platform' do
        expect(StreamerAccount.by_platform('twitch')).to contain_exactly(twitch_account)
      end
    end
  end
  
  describe 'callbacks' do
    describe '#normalize_username' do
      it 'strips whitespace from username' do
        account = create(:streamer_account, username: '  testuser  ')
        expect(account.username).to eq('testuser')
      end
    end
    
    describe '#generate_profile_url' do
      it 'generates Twitch profile URL' do
        account = create(:streamer_account, platform: 'twitch', username: 'testuser', profile_url: nil)
        expect(account.profile_url).to eq('https://twitch.tv/testuser')
      end
      
      it 'generates YouTube profile URL' do
        account = create(:streamer_account, platform: 'youtube', username: 'testuser', profile_url: nil)
        expect(account.profile_url).to eq('https://youtube.com/@testuser')
      end
      
      it 'generates TikTok profile URL' do
        account = create(:streamer_account, platform: 'tiktok', username: 'testuser', profile_url: nil)
        expect(account.profile_url).to eq('https://tiktok.com/@testuser')
      end
      
      it 'does not override existing profile URL' do
        account = create(:streamer_account, platform: 'twitch', username: 'testuser', profile_url: 'https://custom.url')
        expect(account.profile_url).to eq('https://custom.url')
      end
    end
  end
  
  describe 'instance methods' do
    let(:account) { create(:streamer_account, username: 'TestUser', platform: 'twitch') }
    
    describe '#display_name' do
      it 'returns username with platform' do
        expect(account.display_name).to eq('TestUser (twitch)')
      end
    end
    
    describe '#platform_icon' do
      it 'returns icon for known platforms' do
        expect(account.platform_icon).to eq('🎮')
        
        account.platform = 'youtube'
        expect(account.platform_icon).to eq('📺')
        
        account.platform = 'tiktok'
        expect(account.platform_icon).to eq('🎵')
      end
      
      it 'returns generic icon for unknown platform' do
        account.platform = 'other'
        expect(account.platform_icon).to eq('🌐')
      end
    end
    
    describe '#profile_link' do
      it 'returns profile URL when available' do
        account.profile_url = 'https://twitch.tv/testuser'
        expect(account.profile_link).to eq('https://twitch.tv/testuser')
      end
      
      it 'returns placeholder when no URL' do
        account.profile_url = nil
        expect(account.profile_link).to eq('#')
      end
    end
    
    describe '#active?' do
      it 'returns true for active status' do
        account.status = 'active'
        expect(account.active?).to be true
      end
      
      it 'returns false for other statuses' do
        account.status = 'suspended'
        expect(account.active?).to be false
      end
    end
    
    describe '#to_s' do
      it 'returns the display name' do
        expect(account.to_s).to eq('TestUser (twitch)')
      end
    end
  end
  
  describe 'database indexes' do
    it 'has required indexes' do
      expect(ActiveRecord::Base.connection.index_exists?(:streamer_accounts, :streamer_id)).to be true
      expect(ActiveRecord::Base.connection.index_exists?(:streamer_accounts, :platform)).to be true
      expect(ActiveRecord::Base.connection.index_exists?(:streamer_accounts, [:streamer_id, :platform, :username])).to be true
    end
  end
end