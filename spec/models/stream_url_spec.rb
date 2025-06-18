require 'rails_helper'

RSpec.describe StreamUrl, type: :model do
  include ActiveSupport::Testing::TimeHelpers
  describe 'associations' do
    it { is_expected.to belong_to(:streamer).required }
    it { is_expected.to belong_to(:created_by).required }
    it { is_expected.to have_many(:streams).dependent(:nullify) }
  end

  describe 'validations' do
    subject { build(:stream_url) }
    
    it { is_expected.to validate_presence_of(:url) }
    it 'validates url_type is in allowed values' do
      valid_types = %w[stream permalink archive]
      valid_types.each do |type|
        stream_url = build(:stream_url, url_type: type)
        expect(stream_url).to be_valid
      end
      
      # Test invalid value by setting it directly on instance
      invalid_stream_url = build(:stream_url)
      invalid_stream_url.url_type = 'invalid'
      expect(invalid_stream_url).not_to be_valid
    end
    
    it 'validates platform is in allowed values' do
      valid_platforms = %w[TikTok Facebook Twitch YouTube Instagram Other]
      valid_platforms.each do |platform|
        stream_url = build(:stream_url, platform: platform)
        expect(stream_url).to be_valid
      end
      
      # Test invalid value by setting it directly on instance
      invalid_stream_url = build(:stream_url)
      invalid_stream_url.platform = 'InvalidPlatform'
      expect(invalid_stream_url).not_to be_valid
    end
    it { is_expected.to validate_presence_of(:streamer) }
    it { is_expected.to validate_presence_of(:created_by) }
    
    context 'URL format validation' do
      it 'accepts valid URLs' do
        valid_urls = [
          'https://www.tiktok.com/@user/live',
          'https://twitch.tv/user',
          'https://youtube.com/watch?v=123',
          'https://facebook.com/user/live'
        ]
        
        valid_urls.each do |url|
          stream_url = build(:stream_url, url: url)
          expect(stream_url).to be_valid, "Expected #{url} to be valid"
        end
      end
      
      it 'rejects invalid URLs' do
        invalid_urls = [
          'not-a-url',
          'ftp://invalid.com',
          'javascript:alert(1)',
          ''
        ]
        
        invalid_urls.each do |url|
          stream_url = build(:stream_url, url: url)
          expect(stream_url).not_to be_valid, "Expected #{url} to be invalid"
        end
      end
    end
  end

  describe 'enums' do
    describe 'url_type' do
      it 'defines url_type enum with correct values' do
        expect(StreamUrl.url_types).to eq({'stream' => 'stream', 'permalink' => 'permalink', 'archive' => 'archive'})
      end
      
      it 'defaults to stream' do
        stream_url = StreamUrl.new
        expect(stream_url.url_type).to eq('stream')
      end
    end
    
    describe 'platform' do
      it 'defines platform enum with correct values' do
        expect(StreamUrl.platforms).to eq({
          'tiktok' => 'TikTok', 
          'facebook' => 'Facebook', 
          'twitch' => 'Twitch', 
          'youtube' => 'YouTube', 
          'instagram' => 'Instagram', 
          'other' => 'Other'
        })
      end
      
      it 'provides platform prefix methods' do
        stream_url = build(:stream_url, platform: 'TikTok')
        expect(stream_url.platform_tiktok?).to be true
        expect(stream_url.platform_twitch?).to be false
      end
    end
  end

  describe 'scopes' do
    let!(:active_stream_url) { create(:stream_url, is_active: true) }
    let!(:inactive_stream_url) { create(:stream_url, :inactive) }
    let!(:permalink_url) { create(:stream_url, :permalink) }
    let!(:archive_url) { create(:stream_url, :archive) }
    let!(:tiktok_url) { create(:stream_url, platform: 'TikTok') }
    let!(:twitch_url) { create(:stream_url, :twitch) }
    let!(:expired_url) { create(:stream_url, :expired) }
    let!(:expires_soon_url) { create(:stream_url, :expires_soon) }
    
    describe '.active' do
      it 'returns only active stream URLs' do
        expect(StreamUrl.active).to include(active_stream_url, permalink_url, tiktok_url, twitch_url, expired_url, expires_soon_url)
        expect(StreamUrl.active).not_to include(inactive_stream_url, archive_url)
      end
    end
    
    describe '.inactive' do
      it 'returns only inactive stream URLs' do
        expect(StreamUrl.inactive).to include(inactive_stream_url, archive_url)
        expect(StreamUrl.inactive).not_to include(active_stream_url)
      end
    end
    
    describe '.by_type' do
      it 'filters by url_type' do
        expect(StreamUrl.by_type('permalink')).to include(permalink_url)
        expect(StreamUrl.by_type('archive')).to include(archive_url)
        expect(StreamUrl.by_type('stream')).to include(active_stream_url, inactive_stream_url)
      end
    end
    
    describe '.by_platform' do
      it 'filters by platform' do
        expect(StreamUrl.by_platform('TikTok')).to include(tiktok_url, active_stream_url, inactive_stream_url, permalink_url, archive_url, expired_url, expires_soon_url)
        expect(StreamUrl.by_platform('Twitch')).to include(twitch_url)
      end
    end
    
    describe '.by_streamer' do
      it 'filters by streamer' do
        streamer = active_stream_url.streamer
        expect(StreamUrl.by_streamer(streamer)).to include(active_stream_url)
      end
    end
    
    describe '.expires_soon' do
      it 'returns URLs that expire within 1 day' do
        # Create specific test data for this scope
        soon_url = create(:stream_url, expires_at: 30.minutes.from_now)
        future_url = create(:stream_url, expires_at: 2.days.from_now)
        past_url = create(:stream_url, expires_at: 1.day.ago)
        no_expiry_url = create(:stream_url, expires_at: nil)
        
        results = StreamUrl.expires_soon
        expect(results).to include(soon_url)
        expect(results).not_to include(future_url)
        expect(results).not_to include(past_url)
        expect(results).not_to include(no_expiry_url)
      end
    end
    
    describe '.expired' do
      it 'returns URLs that have already expired' do
        expect(StreamUrl.expired).to include(expired_url)
        expect(StreamUrl.expired).not_to include(expires_soon_url, active_stream_url)
      end
    end
    
    describe '.recent' do
      it 'orders by created_at descending' do
        urls = StreamUrl.recent.limit(3)
        expect(urls.first.created_at).to be >= urls.second.created_at
        expect(urls.second.created_at).to be >= urls.third.created_at
      end
    end
    
    describe '.recently_checked' do
      it 'orders by last_checked_at descending' do
        # Update some records to have different last_checked_at times
        active_stream_url.update!(last_checked_at: 1.minute.ago)
        inactive_stream_url.update!(last_checked_at: 1.hour.ago)
        
        urls = StreamUrl.recently_checked.limit(2)
        expect(urls.first.last_checked_at).to be >= urls.second.last_checked_at
      end
    end
  end

  describe 'callbacks' do
    describe 'normalize_url' do
      it 'strips whitespace from URL' do
        stream_url = build(:stream_url, url: '  https://example.com  ')
        stream_url.valid?
        expect(stream_url.url).to eq('https://example.com')
      end
    end
    
    describe 'update_last_checked_at' do
      it 'updates last_checked_at when URL changes' do
        stream_url = create(:stream_url)
        original_time = stream_url.last_checked_at
        
        travel_to(1.hour.from_now) do
          stream_url.update!(url: 'https://newurl.com')
          expect(stream_url.last_checked_at).to be > original_time
        end
      end
      
      it 'does not update last_checked_at when URL does not change' do
        stream_url = create(:stream_url)
        original_time = stream_url.last_checked_at
        
        travel_to(1.hour.from_now) do
          stream_url.update!(title: 'New Title')
          expect(stream_url.last_checked_at).to eq(original_time)
        end
      end
    end
  end

  describe 'instance methods' do
    let(:stream_url) { create(:stream_url) }
    
    describe '#activate!' do
      it 'sets is_active to true' do
        inactive_url = create(:stream_url, :inactive)
        inactive_url.activate!
        expect(inactive_url.reload.is_active).to be true
      end
    end
    
    describe '#deactivate!' do
      it 'sets is_active to false' do
        stream_url.deactivate!
        expect(stream_url.reload.is_active).to be false
      end
    end
    
    describe '#expired?' do
      it 'returns true when expires_at is in the past' do
        expired_url = create(:stream_url, :expired)
        expect(expired_url.expired?).to be true
      end
      
      it 'returns false when expires_at is in the future' do
        future_url = create(:stream_url, expires_at: 1.day.from_now)
        expect(future_url.expired?).to be false
      end
      
      it 'returns false when expires_at is nil' do
        expect(stream_url.expired?).to be false
      end
    end
    
    describe '#expires_soon?' do
      it 'returns true when expires_at is within 1 day' do
        soon_url = create(:stream_url, :expires_soon)
        expect(soon_url.expires_soon?).to be true
      end
      
      it 'returns false when expires_at is more than 1 day away' do
        future_url = create(:stream_url, expires_at: 2.days.from_now)
        expect(future_url.expires_soon?).to be false
      end
      
      it 'returns false when expires_at is nil' do
        expect(stream_url.expires_soon?).to be false
      end
    end
    
    describe '#mark_checked!' do
      it 'updates last_checked_at to current time' do
        travel_to(Time.current) do
          stream_url.mark_checked!
          expect(stream_url.reload.last_checked_at).to be_within(1.second).of(Time.current)
        end
      end
    end
    
    describe '#owned_by?' do
      let(:user) { create(:user) }
      let(:other_user) { create(:user) }
      let(:user_url) { create(:stream_url, created_by: user) }
      
      it 'returns true for the creator' do
        expect(user_url.owned_by?(user)).to be true
      end
      
      it 'returns false for other users' do
        expect(user_url.owned_by?(other_user)).to be false
      end
      
      it 'returns false for nil user' do
        expect(user_url.owned_by?(nil)).to be false
      end
    end
    
    describe '#current_stream?' do
      it 'returns true for active stream type URLs' do
        stream_url = create(:stream_url, url_type: 'stream', is_active: true)
        expect(stream_url.current_stream?).to be true
      end
      
      it 'returns false for inactive stream type URLs' do
        stream_url = create(:stream_url, url_type: 'stream', is_active: false)
        expect(stream_url.current_stream?).to be false
      end
      
      it 'returns false for non-stream type URLs' do
        permalink_url = create(:stream_url, :permalink, is_active: true)
        expect(permalink_url.current_stream?).to be false
      end
    end
    
    describe '#permalink?' do
      it 'returns true for permalink type URLs' do
        permalink_url = create(:stream_url, :permalink)
        expect(permalink_url.permalink?).to be true
      end
      
      it 'returns false for non-permalink type URLs' do
        expect(stream_url.permalink?).to be false
      end
    end
    
    describe '#archived?' do
      it 'returns true for archive type URLs' do
        archive_url = create(:stream_url, :archive)
        expect(archive_url.archived?).to be true
      end
      
      it 'returns false for non-archive type URLs' do
        expect(stream_url.archived?).to be false
      end
    end
  end

  describe 'database indexes' do
    it 'has required indexes' do
      expect(ActiveRecord::Base.connection.index_exists?(:stream_urls, :title)).to be true
      expect(ActiveRecord::Base.connection.index_exists?(:stream_urls, :is_active)).to be true
      expect(ActiveRecord::Base.connection.index_exists?(:stream_urls, :url_type)).to be true
      expect(ActiveRecord::Base.connection.index_exists?(:stream_urls, :platform)).to be true
      expect(ActiveRecord::Base.connection.index_exists?(:stream_urls, [:streamer_id, :is_active])).to be true
      expect(ActiveRecord::Base.connection.index_exists?(:stream_urls, :last_checked_at)).to be true
      expect(ActiveRecord::Base.connection.index_exists?(:stream_urls, :expires_at)).to be true
    end
  end

  describe 'polymorphic created_by association' do
    it 'can be created by a user' do
      user = create(:user)
      stream_url = create(:stream_url, created_by: user)
      expect(stream_url.created_by).to eq(user)
      expect(stream_url.created_by_type).to eq('User')
    end
  end
end
