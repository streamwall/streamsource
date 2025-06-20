require 'rails_helper'

RSpec.describe Stream, type: :model do
  subject { build(:stream) }
  
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:streamer).optional }
    it { should belong_to(:stream_url).optional }
    it { should have_many(:note_records).class_name('Note').dependent(:destroy) }
    it { should have_many(:timestamp_streams).dependent(:destroy) }
    it { should have_many(:timestamps).through(:timestamp_streams) }
  end
  
  describe 'validations' do
    it { should validate_presence_of(:link) }
    it { should validate_presence_of(:source) }
    it { should validate_presence_of(:user) }
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
    
    it 'has unknown status as default' do
      stream = Stream.new
      expect(stream.status).to eq('unknown')
      # Rails sets the default to the key, not the database value
      expect(stream.read_attribute(:status)).to eq('unknown')
    end
    
    it 'has video kind as default' do
      stream = Stream.new
      expect(stream.kind).to eq('video')
    end
  end
  
  describe 'scopes' do
    let!(:user) { create(:user) }
    let!(:streamer) { create(:streamer, user: user) }
    let!(:live_stream) { create(:stream, user: user, status: 'Live', platform: 'YouTube') }
    let!(:offline_stream) { create(:stream, user: user, status: 'Offline', platform: 'Twitch') }
    let!(:archived_stream) { create(:stream, user: user, is_archived: true, status: 'Offline', platform: 'Facebook') }
    let!(:pinned_stream) { create(:stream, user: user, is_pinned: true, status: 'Live', platform: 'Instagram') }
    let!(:streamer_stream) { create(:stream, user: user, streamer: streamer, status: 'Live', platform: 'Other') }
    
    describe '.live' do
      it 'returns only live streams' do
        expect(Stream.live).to contain_exactly(live_stream, pinned_stream, streamer_stream)
      end
    end
    
    describe '.offline' do
      it 'returns only offline streams' do
        expect(Stream.offline).to contain_exactly(offline_stream, archived_stream)
      end
    end
    
    describe '.unknown_status' do
      let!(:unknown_stream) { create(:stream, user: user, status: 'Unknown') }
      
      it 'returns only unknown status streams' do
        expect(Stream.unknown_status).to contain_exactly(unknown_stream)
      end
    end
    
    describe '.active' do
      it 'returns non-archived streams' do
        expect(Stream.active).not_to include(archived_stream)
        expect(Stream.active).to include(live_stream, offline_stream, pinned_stream, streamer_stream)
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
    
    describe '.unpinned' do
      it 'returns only unpinned streams' do
        expect(Stream.unpinned).not_to include(pinned_stream)
        expect(Stream.unpinned).to include(live_stream, offline_stream, streamer_stream, archived_stream)
      end
    end
    
    describe '.by_user' do
      let!(:other_user) { create(:user) }
      let!(:other_stream) { create(:stream, user: other_user, platform: 'YouTube') }
      
      it 'returns streams for specific user' do
        expect(Stream.by_user(user)).not_to include(other_stream)
        expect(Stream.by_user(user)).to include(live_stream, offline_stream, pinned_stream, streamer_stream)
      end
    end
    
    describe '.by_streamer' do
      it 'returns streams for specific streamer' do
        expect(Stream.by_streamer(streamer)).to contain_exactly(streamer_stream)
      end
    end
    
    describe '.by_platform' do
      let!(:tiktok_stream) { create(:stream, user: user, platform: 'TikTok') }
      
      it 'returns streams for specific platform' do
        expect(Stream.by_platform('TikTok')).to contain_exactly(tiktok_stream)
      end
    end
    
    describe '.by_kind' do
      let!(:web_stream) { create(:stream, user: user, kind: 'web') }
      
      it 'returns streams for specific kind' do
        expect(Stream.by_kind('web')).to contain_exactly(web_stream)
      end
    end
    
    describe '.needs_archiving' do
      let!(:old_offline_stream) do
        stream = create(:stream, user: user, status: 'Offline')
        stream.update_column(:last_checked_at, 31.minutes.ago)
        stream
      end
      let!(:recent_offline_stream) do
        stream = create(:stream, user: user, status: 'Offline')
        stream.update_column(:last_checked_at, 10.minutes.ago)
        stream
      end
      
      it 'returns streams that should be archived' do
        expect(Stream.needs_archiving).to include(old_offline_stream)
        expect(Stream.needs_archiving).not_to include(recent_offline_stream, live_stream, archived_stream)
      end
    end
    
    describe '.filtered' do
      let!(:tiktok_live_pinned) { create(:stream, user: user, status: 'Live', platform: 'TikTok', is_pinned: true) }
      
      it 'filters by multiple parameters' do
        filtered = Stream.filtered(
          status: 'Live',
          platform: 'TikTok',
          is_pinned: true
        )
        
        expect(filtered).to contain_exactly(tiktok_live_pinned)
      end
      
      it 'filters by search term' do
        searchable = create(:stream, user: user, source: 'TestStreamer', title: 'Test Stream')
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
    
    describe '#normalize_link' do
      it 'strips whitespace from link' do
        stream = build(:stream, link: '  https://example.com  ')
        stream.save!
        expect(stream.link).to eq('https://example.com')
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
      let(:offline_stream) { create(:stream, user: user, status: 'Offline', started_at: nil) }
      
      it 'updates status and timestamps' do
        offline_stream.mark_as_live!
        expect(offline_stream.status).to eq('live')
        expect(offline_stream.last_checked_at).to be_present
        expect(offline_stream.last_live_at).to be_present
        expect(offline_stream.started_at).to be_present
      end
      
      it 'preserves existing started_at' do
        existing_start = 1.hour.ago
        stream_with_start = create(:stream, user: user, status: 'Offline', started_at: existing_start)
        stream_with_start.mark_as_live!
        expect(stream_with_start.started_at).to be_within(1.second).of(existing_start)
      end
    end
    
    describe '#mark_as_offline!' do
      let(:live_stream) { create(:stream, user: user, status: 'Live') }
      
      it 'updates status to offline' do
        live_stream.mark_as_offline!
        expect(live_stream.status).to eq('offline')
        expect(live_stream.last_checked_at).to be_present
      end
      
      it 'archives stream if should_archive? returns true' do
        allow(live_stream).to receive(:should_archive?).and_return(true)
        expect { live_stream.mark_as_offline! }.to change { live_stream.is_archived }.from(false).to(true)
      end
    end
    
    describe '#mark_as_unknown!' do
      let(:live_stream) { create(:stream, user: user, status: 'Live') }
      
      it 'updates status to unknown' do
        live_stream.mark_as_unknown!
        expect(live_stream.status).to eq('unknown')
        expect(live_stream.last_checked_at).to be_present
      end
      
      it 'archives stream if should_archive? returns true' do
        allow(live_stream).to receive(:should_archive?).and_return(true)
        expect { live_stream.mark_as_unknown! }.to change { live_stream.is_archived }.from(false).to(true)
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
      
      it 'preserves existing ended_at' do
        existing_end = 1.hour.ago
        stream.update!(ended_at: existing_end)
        stream.archive!
        expect(stream.ended_at).to be_within(1.second).of(existing_end)
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
        stream.update!(status: 'Offline')
        stream.update_column(:last_checked_at, 31.minutes.ago)
        expect(stream.should_archive?).to be true
      end
      
      it 'returns false if offline for less than 30 minutes' do
        stream.update!(status: 'Offline')
        stream.update_column(:last_checked_at, 10.minutes.ago)
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
      # Single column indexes
      expect(ActiveRecord::Base.connection.index_exists?(:streams, :user_id)).to be true
      expect(ActiveRecord::Base.connection.index_exists?(:streams, :streamer_id)).to be true
      expect(ActiveRecord::Base.connection.index_exists?(:streams, :status)).to be true
      expect(ActiveRecord::Base.connection.index_exists?(:streams, :is_pinned)).to be true
      expect(ActiveRecord::Base.connection.index_exists?(:streams, :is_archived)).to be true
      expect(ActiveRecord::Base.connection.index_exists?(:streams, :platform)).to be true
      expect(ActiveRecord::Base.connection.index_exists?(:streams, :kind)).to be true
      expect(ActiveRecord::Base.connection.index_exists?(:streams, :last_checked_at)).to be true
      expect(ActiveRecord::Base.connection.index_exists?(:streams, :last_live_at)).to be true
      expect(ActiveRecord::Base.connection.index_exists?(:streams, :started_at)).to be true
      expect(ActiveRecord::Base.connection.index_exists?(:streams, :ended_at)).to be true
      
      # Composite indexes
      expect(ActiveRecord::Base.connection.index_exists?(:streams, [:user_id, :created_at])).to be true
      expect(ActiveRecord::Base.connection.index_exists?(:streams, [:streamer_id, :is_archived])).to be true
      expect(ActiveRecord::Base.connection.index_exists?(:streams, :stream_url_id)).to be true
    end
  end
  
  describe 'StreamUrl integration' do
    let(:streamer) { create(:streamer) }
    let(:stream_url) { create(:stream_url, streamer: streamer) }
    
    describe '#link method' do
      context 'when stream has stream_url' do
        it 'returns URL from stream_url' do
          stream = create(:stream, stream_url: stream_url, link: 'https://old-url.com')
          expect(stream.link).to eq(stream_url.url)
        end
      end
      
      context 'when stream has no stream_url' do
        it 'returns link attribute for backward compatibility' do
          stream = create(:stream, link: 'https://direct-link.com')
          expect(stream.link).to eq('https://direct-link.com')
        end
      end
      
      context 'when stream_url is nil and link is nil' do
        it 'returns nil' do
          stream = build(:stream, link: nil, stream_url: nil)
          expect(stream.link).to be_nil
        end
      end
    end
    
    describe '#link= method' do
      context 'when stream has stream_url' do
        it 'updates both link attribute and stream_url' do
          stream = create(:stream, stream_url: stream_url)
          new_url = 'https://new-url.com'
          
          stream.link = new_url
          stream.save!
          
          expect(stream.read_attribute(:link)).to eq(new_url)
          expect(stream_url.reload.url).to eq(new_url)
        end
      end
      
      context 'when stream has no stream_url' do
        it 'only updates link attribute' do
          stream = create(:stream, link: 'https://old-url.com')
          new_url = 'https://new-url.com'
          
          stream.link = new_url
          stream.save!
          
          expect(stream.read_attribute(:link)).to eq(new_url)
        end
      end
    end
    
    describe '#url delegate' do
      context 'when stream has stream_url' do
        it 'delegates to stream_url.url' do
          stream = build(:stream, stream_url: stream_url)
          expect(stream.url).to eq(stream_url.url)
        end
      end
      
      context 'when stream has no stream_url' do
        it 'returns nil' do
          stream = build(:stream, stream_url: nil)
          expect(stream.url).to be_nil
        end
      end
    end
  end
end