require 'rails_helper'

RSpec.describe Stream, type: :model do
  subject { build(:stream) }
  
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:streamer).optional }
    it { should have_many(:notes).dependent(:destroy) }
    it { should have_many(:annotation_streams).dependent(:destroy) }
    it { should have_many(:annotations).through(:annotation_streams) }
  end
  
  describe 'validations' do
    it { should validate_presence_of(:link) }
    it { should validate_presence_of(:source) }
    it { should validate_length_of(:source).is_at_least(1).is_at_most(255) }
    
    it 'validates URL format' do
      stream = build(:stream, link: 'not-a-url')
      expect(stream).not_to be_valid
      expect(stream.errors[:link]).to include('must be a valid HTTP or HTTPS URL')
    end
    
    it 'accepts valid HTTP URL' do
      stream = build(:stream, link: 'http://example.com')
      expect(stream).to be_valid
    end
    
    it 'accepts valid HTTPS URL' do
      stream = build(:stream, link: 'https://example.com')
      expect(stream).to be_valid
    end
    
    it 'accepts URLs with paths and query strings' do
      stream = build(:stream, link: 'https://example.com/path?query=value&other=123')
      expect(stream).to be_valid
    end
  end
  
  describe 'enums' do
    it { should define_enum_for(:status).with_values(
      live: 'Live', 
      offline: 'Offline', 
      unknown: 'Unknown'
    ).backed_by_column_of_type(:string) }
    
    it { should define_enum_for(:platform).with_values(
      tiktok: 'TikTok',
      facebook: 'Facebook',
      twitch: 'Twitch',
      youtube: 'YouTube',
      instagram: 'Instagram',
      other: 'Other'
    ).with_prefix(true).backed_by_column_of_type(:string) }
    
    it { should define_enum_for(:orientation).with_values(
      vertical: 'vertical',
      horizontal: 'horizontal'
    ).with_prefix(true).backed_by_column_of_type(:string) }
    
    it { should define_enum_for(:kind).with_values(
      video: 'video',
      web: 'web',
      overlay: 'overlay',
      background: 'background'
    ).with_prefix(true).backed_by_column_of_type(:string) }
    
    it 'has Unknown status as default' do
      stream = Stream.new
      expect(stream.status).to eq('Unknown')
    end
    
    it 'has video kind as default' do
      stream = Stream.new
      expect(stream.kind).to eq('video')
    end
  end
  
  describe 'scopes' do
    let!(:user) { create(:user) }
    let!(:streamer) { create(:streamer) }
    let!(:live_stream) { create(:stream, user: user, status: 'Live') }
    let!(:offline_stream) { create(:stream, user: user, status: 'Offline') }
    let!(:archived_stream) { create(:stream, user: user, is_archived: true) }
    let!(:pinned_stream) { create(:stream, user: user, is_pinned: true) }
    let!(:streamer_stream) { create(:stream, user: user, streamer: streamer) }
    
    describe '.live' do
      it 'returns only live streams' do
        expect(Stream.live).to contain_exactly(live_stream)
      end
    end
    
    describe '.offline' do
      it 'returns only offline streams' do
        expect(Stream.offline).to contain_exactly(offline_stream)
      end
    end
    
    describe '.active' do
      it 'returns non-archived streams' do
        expect(Stream.active).not_to include(archived_stream)
        expect(Stream.active).to include(live_stream, offline_stream)
      end
    end
    
    describe '.archived' do
      it 'returns only archived streams' do
        expect(Stream.archived).to contain_exactly(archived_stream)
      end
    end
    
    describe '.pinned' do
      it 'returns only pinned streams' do
        expect(Stream.pinned).to contain_exactly(pinned_stream)
      end
    end
    
    describe '.by_streamer' do
      it 'returns streams for specific streamer' do
        expect(Stream.by_streamer(streamer)).to contain_exactly(streamer_stream)
      end
    end
    
    describe '.needs_archiving' do
      let!(:old_offline_stream) { create(:stream, status: 'Offline', last_checked_at: 31.minutes.ago) }
      let!(:recent_offline_stream) { create(:stream, status: 'Offline', last_checked_at: 10.minutes.ago) }
      
      it 'returns streams that should be archived' do
        expect(Stream.needs_archiving).to include(old_offline_stream)
        expect(Stream.needs_archiving).not_to include(recent_offline_stream, live_stream)
      end
    end
    
    describe '.filtered' do
      it 'filters by multiple parameters' do
        filtered = Stream.filtered(
          status: 'Live',
          platform: 'TikTok',
          is_pinned: true
        )
        
        expect(filtered).to all(
          have_attributes(
            status: 'Live',
            platform: 'TikTok',
            is_pinned: true
          )
        )
      end
      
      it 'filters by search term' do
        searchable = create(:stream, user: user, source: 'TestStreamer')
        filtered = Stream.filtered(search: 'TestStreamer')
        expect(filtered).to include(searchable)
      end
    end
  end
  
  describe 'callbacks' do
    describe 'status tracking' do
      let(:stream) { create(:stream, status: 'Unknown') }
      
      it 'updates last_checked_at when status changes' do
        expect { stream.update!(status: 'Live') }.to change { stream.last_checked_at }
      end
      
      it 'updates last_live_at when going live' do
        expect { stream.update!(status: 'Live') }.to change { stream.last_live_at }
      end
      
      it 'sets started_at when going live for first time' do
        expect(stream.started_at).to be_nil
        stream.update!(status: 'Live')
        expect(stream.started_at).to be_present
      end
      
      it 'does not override existing started_at' do
        original_start = 1.hour.ago
        stream.update!(started_at: original_start)
        stream.update!(status: 'Live')
        expect(stream.started_at).to be_within(1.second).of(original_start)
      end
    end
    
    describe '#set_posted_by' do
      it 'sets posted_by to user email if blank' do
        user = create(:user, email: 'test@example.com')
        stream = build(:stream, user: user, posted_by: nil)
        stream.save!
        expect(stream.posted_by).to eq('test@example.com')
      end
      
      it 'does not override existing posted_by' do
        stream = build(:stream, posted_by: 'CustomPoster')
        stream.save!
        expect(stream.posted_by).to eq('CustomPoster')
      end
    end
  end
  
  describe 'instance methods' do
    let(:user) { create(:user) }
    let(:admin) { create(:user, :admin) }
    let(:stream) { create(:stream, user: user) }
    
    describe '#owned_by?' do
      it 'returns true for owner' do
        expect(stream.owned_by?(user)).to be true
      end
      
      it 'returns false for non-owner' do
        expect(stream.owned_by?(admin)).to be false
      end
      
      it 'returns false for nil user' do
        expect(stream.owned_by?(nil)).to be false
      end
    end
    
    describe '#pin!' do
      it 'sets is_pinned to true' do
        expect { stream.pin! }.to change { stream.is_pinned }.from(false).to(true)
      end
    end
    
    describe '#unpin!' do
      let(:pinned_stream) { create(:stream, user: user, is_pinned: true) }
      
      it 'sets is_pinned to false' do
        expect { pinned_stream.unpin! }.to change { pinned_stream.is_pinned }.from(true).to(false)
      end
    end
    
    describe '#toggle_pin!' do
      it 'toggles is_pinned state' do
        expect { stream.toggle_pin! }.to change { stream.is_pinned }.from(false).to(true)
        expect { stream.toggle_pin! }.to change { stream.is_pinned }.from(true).to(false)
      end
    end
    
    describe '#mark_as_live!' do
      it 'updates status and timestamps' do
        stream.mark_as_live!
        expect(stream.status).to eq('Live')
        expect(stream.last_checked_at).to be_present
        expect(stream.last_live_at).to be_present
        expect(stream.started_at).to be_present
      end
    end
    
    describe '#mark_as_offline!' do
      it 'updates status to offline' do
        stream.mark_as_offline!
        expect(stream.status).to eq('Offline')
        expect(stream.last_checked_at).to be_present
      end
      
      it 'archives stream if should_archive? returns true' do
        allow(stream).to receive(:should_archive?).and_return(true)
        expect { stream.mark_as_offline! }.to change { stream.is_archived }.from(false).to(true)
      end
    end
    
    describe '#archive!' do
      it 'sets is_archived to true' do
        expect { stream.archive! }.to change { stream.is_archived }.from(false).to(true)
      end
      
      it 'sets ended_at if not already set' do
        stream.archive!
        expect(stream.ended_at).to be_present
      end
      
      it 'does not archive if already archived' do
        stream.update!(is_archived: true)
        expect { stream.archive! }.not_to change { stream.updated_at }
      end
    end
    
    describe '#should_archive?' do
      it 'returns false if already archived' do
        stream.update!(is_archived: true)
        expect(stream.should_archive?).to be false
      end
      
      it 'returns false if live' do
        stream.update!(status: 'Live')
        expect(stream.should_archive?).to be false
      end
      
      it 'returns true if offline for more than 30 minutes' do
        stream.update!(status: 'Offline', last_checked_at: 31.minutes.ago)
        expect(stream.should_archive?).to be true
      end
      
      it 'returns false if offline for less than 30 minutes' do
        stream.update!(status: 'Offline', last_checked_at: 10.minutes.ago)
        expect(stream.should_archive?).to be false
      end
    end
    
    describe '#duration' do
      it 'returns nil if started_at is nil' do
        stream.update!(started_at: nil)
        expect(stream.duration).to be_nil
      end
      
      it 'calculates duration from started_at to ended_at' do
        stream.update!(started_at: 2.hours.ago, ended_at: 1.hour.ago)
        expect(stream.duration).to be_within(1).of(3600)
      end
      
      it 'calculates duration from started_at to current time if not ended' do
        stream.update!(started_at: 1.hour.ago, ended_at: nil)
        expect(stream.duration).to be_within(10).of(3600)
      end
    end
    
    describe '#duration_in_words' do
      it 'returns nil if duration is nil' do
        stream.update!(started_at: nil)
        expect(stream.duration_in_words).to be_nil
      end
      
      it 'formats hours and minutes' do
        stream.update!(started_at: 2.hours.ago - 30.minutes, ended_at: Time.current)
        expect(stream.duration_in_words).to eq('2h 30m')
      end
      
      it 'formats minutes only when less than an hour' do
        stream.update!(started_at: 45.minutes.ago, ended_at: Time.current)
        expect(stream.duration_in_words).to eq('45m')
      end
    end
  end
  
  describe 'database indexes' do
    it 'has required indexes' do
      expect(ActiveRecord::Base.connection.index_exists?(:streams, :user_id)).to be true
      expect(ActiveRecord::Base.connection.index_exists?(:streams, :streamer_id)).to be true
      expect(ActiveRecord::Base.connection.index_exists?(:streams, :status)).to be true
      expect(ActiveRecord::Base.connection.index_exists?(:streams, :is_pinned)).to be true
      expect(ActiveRecord::Base.connection.index_exists?(:streams, :is_archived)).to be true
      expect(ActiveRecord::Base.connection.index_exists?(:streams, :platform)).to be true
      expect(ActiveRecord::Base.connection.index_exists?(:streams, :last_checked_at)).to be true
      expect(ActiveRecord::Base.connection.index_exists?(:streams, :last_live_at)).to be true
    end
  end
end