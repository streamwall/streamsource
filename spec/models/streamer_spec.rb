require 'rails_helper'

RSpec.describe Streamer, type: :model do
  subject { build(:streamer) }
  
  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:streamer_accounts).dependent(:destroy) }
    it { should have_many(:streams).dependent(:nullify) }
    it { should have_many(:notes).dependent(:destroy) }
    it { should have_many(:annotation_streams).through(:streams) }
    it { should have_many(:annotations).through(:annotation_streams) }
  end
  
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_least(2).is_at_most(100) }
    it { should validate_length_of(:bio).is_at_most(500) }
    it { should validate_length_of(:notes).is_at_most(1000) }
    
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
  
  describe 'enums' do
    it { should define_enum_for(:status).with_values(
      active: 'active',
      inactive: 'inactive',
      banned: 'banned'
    ).with_prefix(true) }
  end
  
  describe 'scopes' do
    let!(:user) { create(:user) }
    let!(:active_streamer) { create(:streamer, user: user, status: 'active') }
    let!(:inactive_streamer) { create(:streamer, user: user, status: 'inactive') }
    let!(:banned_streamer) { create(:streamer, user: user, status: 'banned') }
    let!(:featured_streamer) { create(:streamer, user: user, is_featured: true) }
    
    describe '.active' do
      it 'returns only active streamers' do
        expect(Streamer.active).to contain_exactly(active_streamer, featured_streamer)
      end
    end
    
    describe '.featured' do
      it 'returns only featured streamers' do
        expect(Streamer.featured).to contain_exactly(featured_streamer)
      end
    end
    
    describe '.alphabetical' do
      it 'orders by name alphabetically' do
        zebra = create(:streamer, name: 'Zebra')
        alpha = create(:streamer, name: 'Alpha')
        
        expect(Streamer.alphabetical.first).to eq(alpha)
        expect(Streamer.alphabetical.last).to eq(zebra)
      end
    end
    
    describe '.with_platforms' do
      it 'includes streamer_accounts association' do
        streamer = create(:streamer)
        create(:streamer_account, streamer: streamer, platform: 'twitch')
        
        loaded = Streamer.with_platforms.find(streamer.id)
        expect(loaded.association(:streamer_accounts)).to be_loaded
      end
    end
  end
  
  describe 'instance methods' do
    let(:user) { create(:user) }
    let(:streamer) { create(:streamer, user: user) }
    
    describe '#platforms' do
      it 'returns unique platform names' do
        create(:streamer_account, streamer: streamer, platform: 'twitch')
        create(:streamer_account, streamer: streamer, platform: 'youtube')
        create(:streamer_account, streamer: streamer, platform: 'twitch', username: 'alt_account')
        
        expect(streamer.platforms).to contain_exactly('twitch', 'youtube')
      end
      
      it 'returns empty array when no accounts' do
        expect(streamer.platforms).to eq([])
      end
    end
    
    describe '#primary_platform' do
      it 'returns first platform alphabetically' do
        create(:streamer_account, streamer: streamer, platform: 'youtube')
        create(:streamer_account, streamer: streamer, platform: 'twitch')
        
        expect(streamer.primary_platform).to eq('twitch')
      end
      
      it 'returns nil when no accounts' do
        expect(streamer.primary_platform).to be_nil
      end
    end
    
    describe '#platform_accounts' do
      it 'returns accounts for specific platform' do
        twitch1 = create(:streamer_account, streamer: streamer, platform: 'twitch', username: 'main')
        twitch2 = create(:streamer_account, streamer: streamer, platform: 'twitch', username: 'alt')
        youtube = create(:streamer_account, streamer: streamer, platform: 'youtube')
        
        expect(streamer.platform_accounts('twitch')).to contain_exactly(twitch1, twitch2)
        expect(streamer.platform_accounts('youtube')).to contain_exactly(youtube)
      end
    end
    
    describe '#has_platform?' do
      it 'returns true when platform exists' do
        create(:streamer_account, streamer: streamer, platform: 'twitch')
        expect(streamer.has_platform?('twitch')).to be true
      end
      
      it 'returns false when platform does not exist' do
        expect(streamer.has_platform?('twitch')).to be false
      end
    end
    
    describe '#active_streams' do
      it 'returns non-archived streams' do
        active_stream = create(:stream, streamer: streamer, is_archived: false)
        archived_stream = create(:stream, streamer: streamer, is_archived: true)
        
        expect(streamer.active_streams).to contain_exactly(active_stream)
      end
    end
    
    describe '#live_streams' do
      it 'returns streams with Live status' do
        live_stream = create(:stream, streamer: streamer, status: 'Live')
        offline_stream = create(:stream, streamer: streamer, status: 'Offline')
        
        expect(streamer.live_streams).to contain_exactly(live_stream)
      end
    end
    
    describe '#total_stream_count' do
      it 'counts all associated streams' do
        create_list(:stream, 3, streamer: streamer)
        expect(streamer.total_stream_count).to eq(3)
      end
    end
    
    describe '#active_stream_count' do
      it 'counts non-archived streams' do
        create_list(:stream, 2, streamer: streamer, is_archived: false)
        create(:stream, streamer: streamer, is_archived: true)
        
        expect(streamer.active_stream_count).to eq(2)
      end
    end
    
    describe '#is_live?' do
      it 'returns true when any stream is live' do
        create(:stream, streamer: streamer, status: 'Live')
        expect(streamer.is_live?).to be true
      end
      
      it 'returns false when no streams are live' do
        create(:stream, streamer: streamer, status: 'Offline')
        expect(streamer.is_live?).to be false
      end
    end
    
    describe '#owned_by?' do
      it 'returns true for owner' do
        expect(streamer.owned_by?(user)).to be true
      end
      
      it 'returns false for non-owner' do
        other_user = create(:user)
        expect(streamer.owned_by?(other_user)).to be false
      end
      
      it 'returns false for nil user' do
        expect(streamer.owned_by?(nil)).to be false
      end
    end
    
    describe '#to_s' do
      it 'returns the name' do
        streamer.name = 'TestStreamer'
        expect(streamer.to_s).to eq('TestStreamer')
      end
    end
  end
  
  describe 'database indexes' do
    it 'has required indexes' do
      expect(ActiveRecord::Base.connection.index_exists?(:streamers, :user_id)).to be true
      expect(ActiveRecord::Base.connection.index_exists?(:streamers, :name)).to be true
      expect(ActiveRecord::Base.connection.index_exists?(:streamers, :status)).to be true
      expect(ActiveRecord::Base.connection.index_exists?(:streamers, :is_featured)).to be true
    end
  end
end