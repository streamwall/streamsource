require 'rails_helper'

RSpec.describe Streamer, type: :model do
  subject { build(:streamer) }
  
  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:streamer_accounts).dependent(:destroy) }
    it { should have_many(:streams).dependent(:destroy) }
    it { should have_many(:note_records).class_name('Note').dependent(:destroy) }
    it { should have_many(:timestamp_streams).through(:streams) }
    it { should have_many(:timestamps).through(:timestamp_streams) }
  end
  
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:user) }
    
    it 'validates uniqueness of name' do
      create(:streamer, name: 'TestStreamer')
      duplicate = build(:streamer, name: 'TestStreamer')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include('has already been taken')
    end
    
    it 'validates uniqueness case-insensitively' do
      create(:streamer, name: 'TestStreamer')
      duplicate = build(:streamer, name: 'teststreamer')
      expect(duplicate).not_to be_valid
    end
  end
  
  describe 'scopes' do
    let!(:user) { create(:user) }
    let!(:streamer) { create(:streamer, user: user) }
    let!(:other_streamer) { create(:streamer, user: user) }
    
    describe '.with_active_accounts' do
      it 'returns streamers with active accounts' do
        create(:streamer_account, streamer: streamer, is_active: true)
        create(:streamer_account, streamer: other_streamer, is_active: false)
        
        expect(Streamer.with_active_accounts).to include(streamer)
        expect(Streamer.with_active_accounts).not_to include(other_streamer)
      end
    end
    
    describe '.by_platform' do
      it 'returns streamers by platform' do
        create(:streamer_account, streamer: streamer, platform: 'twitch')
        create(:streamer_account, streamer: other_streamer, platform: 'youtube')
        
        expect(Streamer.by_platform('twitch')).to include(streamer)
        expect(Streamer.by_platform('twitch')).not_to include(other_streamer)
      end
    end
    
    describe '.with_live_streams' do
      it 'returns streamers with live streams' do
        create(:stream, streamer: streamer, status: 'live', is_archived: false)
        create(:stream, streamer: other_streamer, status: 'offline')
        
        expect(Streamer.with_live_streams).to include(streamer)
        expect(Streamer.with_live_streams).not_to include(other_streamer)
      end
    end
    
    describe '.recently_active' do
      it 'returns streamers with recent streams' do
        create(:stream, streamer: streamer, last_live_at: 2.days.ago)
        create(:stream, streamer: other_streamer, last_live_at: 10.days.ago)
        
        expect(Streamer.recently_active).to include(streamer)
        expect(Streamer.recently_active).not_to include(other_streamer)
      end
    end
    
    describe '.search' do
      it 'searches by name' do
        streamer1 = create(:streamer, name: 'GamePlayer')
        streamer2 = create(:streamer, name: 'SportsFan')
        
        expect(Streamer.search('Game')).to include(streamer1)
        expect(Streamer.search('Game')).not_to include(streamer2)
      end
      
      it 'is case insensitive' do
        streamer = create(:streamer, name: 'GamePlayer')
        expect(Streamer.search('game')).to include(streamer)
      end
    end
  end
  
  describe 'callbacks' do
    describe '#normalize_name' do
      it 'strips whitespace from name' do
        streamer = build(:streamer, name: '  TestStreamer  ')
        streamer.save
        expect(streamer.name).to eq('TestStreamer')
      end
    end
    
    describe '#set_posted_by' do
      it 'sets posted_by to user email if not provided' do
        user = create(:user, email: 'test@example.com')
        streamer = create(:streamer, user: user, posted_by: nil)
        expect(streamer.posted_by).to eq('test@example.com')
      end
      
      it 'does not override existing posted_by' do
        streamer = create(:streamer, posted_by: 'custom@example.com')
        expect(streamer.posted_by).to eq('custom@example.com')
      end
    end
  end
  
  describe 'instance methods' do
    let(:user) { create(:user) }
    let(:streamer) { create(:streamer, user: user) }
    
    describe '#active_stream' do
      it 'returns the most recent live non-archived stream' do
        old_live = create(:stream, streamer: streamer, status: 'live', started_at: 2.hours.ago)
        recent_live = create(:stream, streamer: streamer, status: 'live', started_at: 1.hour.ago)
        archived = create(:stream, streamer: streamer, status: 'live', is_archived: true)
        
        expect(streamer.active_stream).to eq(recent_live)
      end
      
      it 'returns nil when no active streams' do
        create(:stream, streamer: streamer, status: 'offline')
        expect(streamer.active_stream).to be_nil
      end
    end
    
    describe '#last_stream' do
      it 'returns the most recent stream by started_at' do
        old_stream = create(:stream, streamer: streamer, started_at: 2.days.ago)
        new_stream = create(:stream, streamer: streamer, started_at: 1.day.ago)
        
        expect(streamer.last_stream).to eq(new_stream)
      end
    end
    
    describe '#platforms' do
      it 'returns unique platform names for active accounts' do
        create(:streamer_account, streamer: streamer, platform: 'twitch', is_active: true)
        create(:streamer_account, streamer: streamer, platform: 'youtube', is_active: true)
        create(:streamer_account, streamer: streamer, platform: 'twitch', username: 'alt_account', is_active: true)
        create(:streamer_account, streamer: streamer, platform: 'facebook', is_active: false)
        
        expect(streamer.platforms).to contain_exactly('twitch', 'youtube')
      end
      
      it 'returns empty array when no active accounts' do
        expect(streamer.platforms).to eq([])
      end
    end
    
    describe '#account_for_platform' do
      it 'returns active account for platform' do
        account = create(:streamer_account, streamer: streamer, platform: 'twitch', is_active: true)
        inactive = create(:streamer_account, streamer: streamer, platform: 'youtube', is_active: false)
        
        expect(streamer.account_for_platform('twitch')).to eq(account)
        expect(streamer.account_for_platform('youtube')).to be_nil
      end
    end
    
    describe '#create_or_continue_stream!' do
      it 'creates a new stream when no recent stream exists' do
        expect {
          streamer.create_or_continue_stream!(link: 'https://twitch.tv/test', source: 'twitch')
        }.to change { streamer.streams.count }.by(1)
        
        stream = streamer.streams.last
        expect(stream.status).to eq('live')
        expect(stream.last_checked_at).to be_present
        expect(stream.last_live_at).to be_present
      end
      
      it 'continues existing stream if checked recently' do
        existing = create(:stream, 
          streamer: streamer,
          last_checked_at: 15.minutes.ago,
          is_archived: false
        )
        
        expect {
          streamer.create_or_continue_stream!(link: 'https://twitch.tv/test', source: 'twitch')
        }.not_to change { streamer.streams.count }
        
        existing.reload
        expect(existing.status).to eq('live')
        expect(existing.last_checked_at).to be > 1.minute.ago
      end
      
      it 'creates new stream if existing stream is old' do
        # Create an old stream that should not be reused
        # First create it, then update last_checked_at directly to avoid callbacks
        existing = create(:stream, 
          streamer: streamer,
          user: user,
          is_archived: false,
          status: 'offline'
        )
        
        # Update last_checked_at directly to bypass callbacks
        existing.update_column(:last_checked_at, 2.hours.ago)
        existing.reload
        
        # Verify the stream was created with correct attributes
        expect(existing.last_checked_at).to be < 30.minutes.ago
        expect(existing.streamer).to eq(streamer)
        
        expect {
          streamer.create_or_continue_stream!(link: 'https://twitch.tv/test', source: 'twitch')
        }.to change { streamer.streams.count }.by(1)
      end
    end
    
  end
  
  describe 'database indexes' do
    it 'has required indexes' do
      expect(ActiveRecord::Base.connection.index_exists?(:streamers, :user_id)).to be true
      expect(ActiveRecord::Base.connection.index_exists?(:streamers, :name)).to be true
    end
  end
end