require 'rails_helper'

RSpec.describe Timestamp, type: :model do
  subject { build(:timestamp) }
  
  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:timestamp_streams).dependent(:destroy) }
    it { should have_many(:streams).through(:timestamp_streams) }
  end
  
  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_length_of(:title).is_at_least(3).is_at_most(200) }
    it { should validate_length_of(:description).is_at_most(2000) }
    it { should validate_presence_of(:event_timestamp) }
  end
  
  describe 'scopes' do
    let!(:user) { create(:user) }
    let!(:today_timestamp) { create(:timestamp, user: user, event_timestamp: Time.current) }
    let!(:old_timestamp) { create(:timestamp, user: user, event_timestamp: 2.weeks.ago) }
    
    describe '.recent' do
      it 'orders by event_timestamp descending' do
        expect(Timestamp.recent.first).to eq(today_timestamp)
        expect(Timestamp.recent.last).to eq(old_timestamp)
      end
    end
    
    describe '.occurred_today' do
      it 'returns timestamps from today' do
        expect(Timestamp.occurred_today).to include(today_timestamp)
        expect(Timestamp.occurred_today).not_to include(old_timestamp)
      end
    end
    
    describe '.filtered' do
      it 'filters by search term' do
        searchable = create(:timestamp, user: user, title: 'Major earthquake', description: 'Significant damage')
        filtered = Timestamp.filtered(search: 'earthquake')
        expect(filtered).to include(searchable)
      end
      
      it 'filters by date range' do
        old_timestamp = create(:timestamp, user: user, event_timestamp: 10.days.ago)
        recent_timestamp = create(:timestamp, user: user, event_timestamp: 2.days.ago)
        future_timestamp = create(:timestamp, user: user, event_timestamp: 2.days.from_now)
        
        filtered = Timestamp.filtered(start_date: 5.days.ago, end_date: 1.day.ago)
        expect(filtered).to include(recent_timestamp)
        expect(filtered).not_to include(old_timestamp, future_timestamp)
      end
    end
    
    describe '.created_recently' do
      it 'returns timestamps created in last 7 days' do
        old = create(:timestamp, user: user, created_at: 8.days.ago)
        recent = create(:timestamp, user: user, created_at: 3.days.ago)
        
        expect(Timestamp.created_recently).to include(recent)
        expect(Timestamp.created_recently).not_to include(old)
      end
    end
    
    describe '.occurred_between' do
      it 'returns timestamps with events between dates' do
        before = create(:timestamp, user: user, event_timestamp: 10.days.ago)
        during = create(:timestamp, user: user, event_timestamp: 5.days.ago)
        after = create(:timestamp, user: user, event_timestamp: 1.day.ago)
        
        result = Timestamp.occurred_between(7.days.ago, 3.days.ago)
        expect(result).to include(during)
        expect(result).not_to include(before, after)
      end
    end
    
    describe '.occurred_this_week' do
      it 'returns timestamps from current week' do
        last_week = create(:timestamp, user: user, event_timestamp: 1.week.ago - 1.day)
        this_week = create(:timestamp, user: user, event_timestamp: 2.days.ago)
        
        expect(Timestamp.occurred_this_week).to include(this_week)
        expect(Timestamp.occurred_this_week).not_to include(last_week)
      end
    end
  end
  
  describe 'instance methods' do
    let(:user) { create(:user) }
    let(:admin) { create(:user, :admin) }
    let(:timestamp) { create(:timestamp, user: user) }
    
    describe '#owned_by?' do
      it 'returns true for owner' do
        expect(timestamp.owned_by?(user)).to be true
      end
      
      it 'returns false for non-owner' do
        expect(timestamp.owned_by?(admin)).to be false
      end
      
      it 'returns false for nil user' do
        expect(timestamp.owned_by?(nil)).to be false
      end
    end
    
    describe '#add_stream!' do
      let(:stream) { create(:stream) }
      
      it 'creates timestamp_stream association' do
        expect {
          timestamp.add_stream!(stream, user, timestamp_seconds: 120)
        }.to change { timestamp.timestamp_streams.count }.by(1)
        
        timestamp_stream = timestamp.timestamp_streams.last
        expect(timestamp_stream.stream).to eq(stream)
        expect(timestamp_stream.added_by_user).to eq(user)
        expect(timestamp_stream.stream_timestamp_seconds).to eq(120)
      end
    end
    
    describe '#formatted_event_time' do
      it 'formats event timestamp' do
        timestamp = create(:timestamp, user: user, event_timestamp: Time.zone.parse('2024-01-15 14:30:00'))
        expect(timestamp.formatted_event_time).to eq('Jan 15, 2024 at 2:30 PM')
      end
    end
    
    describe '#time_ago' do
      context 'with minutes' do
        it 'returns singular minute' do
          timestamp = create(:timestamp, user: user, event_timestamp: 1.minute.ago)
          expect(timestamp.time_ago).to eq('1 minute ago')
        end
        
        it 'returns plural minutes' do
          timestamp = create(:timestamp, user: user, event_timestamp: 45.minutes.ago)
          expect(timestamp.time_ago).to eq('45 minutes ago')
        end
      end
      
      context 'with hours' do
        it 'returns singular hour' do
          timestamp = create(:timestamp, user: user, event_timestamp: 1.hour.ago)
          expect(timestamp.time_ago).to eq('1 hour ago')
        end
        
        it 'returns plural hours' do
          timestamp = create(:timestamp, user: user, event_timestamp: 3.hours.ago)
          expect(timestamp.time_ago).to eq('3 hours ago')
        end
      end
      
      context 'with days' do
        it 'returns singular day' do
          timestamp = create(:timestamp, user: user, event_timestamp: 1.day.ago)
          expect(timestamp.time_ago).to eq('1 day ago')
        end
        
        it 'returns plural days' do
          timestamp = create(:timestamp, user: user, event_timestamp: 5.days.ago)
          expect(timestamp.time_ago).to eq('5 days ago')
        end
      end
      
      context 'with edge cases' do
        it 'returns just now for very recent' do
          timestamp = create(:timestamp, user: user, event_timestamp: 5.seconds.ago)
          expect(timestamp.time_ago).to eq('just now')
        end
        
        it 'handles future timestamps' do
          timestamp = create(:timestamp, user: user, event_timestamp: 1.hour.from_now)
          expect(timestamp.time_ago).to eq('in the future')
        end
      end
    end
    
    describe '#stream_count' do
      it 'returns number of associated streams' do
        timestamp = create(:timestamp, user: user)
        stream1 = create(:stream)
        stream2 = create(:stream)
        
        timestamp.add_stream!(stream1, user)
        timestamp.add_stream!(stream2, user)
        
        expect(timestamp.stream_count).to eq(2)
      end
    end
    
    describe '#remove_stream!' do
      it 'removes stream association' do
        timestamp = create(:timestamp, user: user)
        stream = create(:stream)
        timestamp.add_stream!(stream, user)
        
        expect {
          timestamp.remove_stream!(stream)
        }.to change { timestamp.streams.count }.by(-1)
        
        expect(timestamp.streams).not_to include(stream)
      end
    end
  end
  
  describe 'database indexes' do
    it 'has required indexes' do
      expect(ActiveRecord::Base.connection.index_exists?(:timestamps, :event_timestamp)).to be true
    end
  end
end