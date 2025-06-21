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
  end
  
  describe 'database indexes' do
    it 'has required indexes' do
      expect(ActiveRecord::Base.connection.index_exists?(:timestamps, :event_timestamp)).to be true
    end
  end
end