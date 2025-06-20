require 'rails_helper'

RSpec.describe Note, type: :model do
  subject { build(:note) }
  
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:notable) }
  end
  
  describe 'validations' do
    it { should validate_presence_of(:content) }
    it { should validate_length_of(:content).is_at_least(1).is_at_most(2000) }
  end
  
  describe 'polymorphic associations' do
    let(:user) { create(:user) }
    
    it 'can belong to a stream' do
      stream = create(:stream)
      note = create(:note, notable: stream, user: user)
      expect(note.notable).to eq(stream)
      expect(note.notable_type).to eq('Stream')
    end
    
    it 'can belong to a streamer' do
      streamer = create(:streamer)
      note = create(:note, notable: streamer, user: user)
      expect(note.notable).to eq(streamer)
      expect(note.notable_type).to eq('Streamer')
    end
    
    it 'can belong to a timestamp' do
      timestamp = create(:timestamp)
      note = create(:note, notable: timestamp, user: user)
      expect(note.notable).to eq(timestamp)
      expect(note.notable_type).to eq('Timestamp')
    end
  end
  
  describe 'scopes' do
    let!(:user) { create(:user) }
    let!(:newest_note) { create(:note, user: user, created_at: 1.hour.ago) }
    let!(:oldest_note) { create(:note, user: user, created_at: 1.day.ago) }
    let!(:middle_note) { create(:note, user: user, created_at: 6.hours.ago) }
    
    describe '.recent' do
      it 'orders by created_at descending' do
        expect(Note.recent.first).to eq(newest_note)
        expect(Note.recent.last).to eq(oldest_note)
      end
    end
    
    describe '.by_user' do
      let!(:other_user) { create(:user) }
      let!(:other_note) { create(:note, user: other_user) }
      
      it 'returns notes for specific user' do
        expect(Note.by_user(user)).to contain_exactly(newest_note, oldest_note, middle_note)
        expect(Note.by_user(user)).not_to include(other_note)
      end
    end
    
    describe '.for_streams' do
      let!(:stream_note) { create(:note, notable: create(:stream), user: user) }
      let!(:streamer_note) { create(:note, notable: create(:streamer), user: user) }
      
      it 'returns notes for streams only' do
        expect(Note.for_streams).to include(stream_note)
        expect(Note.for_streams).not_to include(streamer_note)
      end
    end
    
    describe '.for_streamers' do
      let!(:stream_note) { create(:note, notable: create(:stream), user: user) }
      let!(:streamer_note) { create(:note, notable: create(:streamer), user: user) }
      
      it 'returns notes for streamers only' do
        expect(Note.for_streamers).to include(streamer_note)
        expect(Note.for_streamers).not_to include(stream_note)
      end
    end
  end
  
  describe 'instance methods' do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let(:note) { create(:note, user: user) }
    
    describe '#owned_by?' do
      it 'returns true for the author' do
        expect(note.owned_by?(user)).to be true
      end
      
      it 'returns false for other users' do
        expect(note.owned_by?(other_user)).to be false
      end
      
      it 'returns false for nil user' do
        expect(note.owned_by?(nil)).to be false
      end
    end
    
    describe '#truncated_content' do
      it 'truncates long content' do
        note = create(:note, content: 'a' * 200)
        expect(note.truncated_content(50)).to eq('a' * 50 + '...')
      end
      
      it 'returns full content if shorter than limit' do
        note = create(:note, content: 'Short note')
        expect(note.truncated_content(50)).to eq('Short note')
      end
      
      it 'uses default limit of 100' do
        note = create(:note, content: 'a' * 200)
        expect(note.truncated_content).to eq('a' * 100 + '...')
      end
    end
  end
  
  describe 'database indexes' do
    it 'has required indexes' do
      expect(ActiveRecord::Base.connection.index_exists?(:notes, :user_id)).to be true
      expect(ActiveRecord::Base.connection.index_exists?(:notes, [:notable_type, :notable_id])).to be true
      expect(ActiveRecord::Base.connection.index_exists?(:notes, :created_at)).to be true
    end
  end
  
  describe 'character counting' do
    it 'respects the 2000 character limit' do
      note = build(:note, content: 'a' * 2001)
      expect(note).not_to be_valid
      expect(note.errors[:content]).to include('is too long (maximum is 2000 characters)')
    end
    
    it 'allows exactly 2000 characters' do
      note = build(:note, content: 'a' * 2000)
      expect(note).to be_valid
    end
    
    it 'requires at least 1 character' do
      note = build(:note, content: '')
      expect(note).not_to be_valid
      expect(note.errors[:content]).to include("can't be blank")
    end
  end
end