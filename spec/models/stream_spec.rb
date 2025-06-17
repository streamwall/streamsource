require 'rails_helper'

RSpec.describe Stream, type: :model do
  subject { build(:stream) }
  
  describe 'associations' do
    it { should belong_to(:user) }
  end
  
  describe 'validations' do
    it { should validate_presence_of(:url) }
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_least(1).is_at_most(255) }
    
    it 'validates URL format' do
      stream = build(:stream, url: 'not-a-url')
      expect(stream).not_to be_valid
      expect(stream.errors[:url]).to include('must be a valid HTTP or HTTPS URL')
    end
    
    it 'accepts valid HTTP URL' do
      stream = build(:stream, url: 'http://example.com')
      expect(stream).to be_valid
    end
    
    it 'accepts valid HTTPS URL' do
      stream = build(:stream, url: 'https://example.com')
      expect(stream).to be_valid
    end
    
    it 'accepts URLs with paths and query strings' do
      stream = build(:stream, url: 'https://example.com/path?query=value&other=123')
      expect(stream).to be_valid
    end
  end
  
  describe 'enums' do
    it { should define_enum_for(:status).with_values(active: 'active', inactive: 'inactive') }
    
    it 'has active status as default' do
      stream = Stream.new
      expect(stream.status).to eq('active')
    end
  end
  
  describe 'scopes' do
    let!(:user) { create(:user) }
    let!(:other_user) { create(:user) }
    let!(:active_stream) { create(:stream, user: user, status: 'active') }
    let!(:inactive_stream) { create(:stream, user: user, status: 'inactive') }
    let!(:pinned_stream) { create(:stream, user: user, is_pinned: true) }
    let!(:other_user_stream) { create(:stream, user: other_user) }
    
    describe '.active' do
      it 'returns only active streams' do
        expect(Stream.active).to contain_exactly(active_stream, pinned_stream, other_user_stream)
      end
    end
    
    describe '.pinned' do
      it 'returns only pinned streams' do
        expect(Stream.pinned).to contain_exactly(pinned_stream)
      end
    end
    
    describe '.by_user' do
      it 'returns streams for specific user' do
        expect(Stream.by_user(user)).to contain_exactly(active_stream, inactive_stream, pinned_stream)
      end
    end
    
    describe '.ordered' do
      it 'orders by pinned first, then by created_at descending' do
        newest = create(:stream, user: user, created_at: 1.hour.ago)
        oldest = create(:stream, user: user, created_at: 1.day.ago)
        
        ordered = Stream.ordered
        expect(ordered.first).to eq(pinned_stream)
        expect(ordered[1]).to eq(newest)
        expect(ordered.last).to eq(oldest)
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
      
      it 'persists the change' do
        stream.pin!
        expect(stream.reload.is_pinned).to be true
      end
    end
    
    describe '#unpin!' do
      let(:pinned_stream) { create(:stream, user: user, is_pinned: true) }
      
      it 'sets is_pinned to false' do
        expect { pinned_stream.unpin! }.to change { pinned_stream.is_pinned }.from(true).to(false)
      end
      
      it 'persists the change' do
        pinned_stream.unpin!
        expect(pinned_stream.reload.is_pinned).to be false
      end
    end
  end
  
  describe 'database indexes' do
    it 'has index on user_id' do
      expect(ActiveRecord::Base.connection.index_exists?(:streams, :user_id)).to be true
    end
    
    it 'has index on status' do
      expect(ActiveRecord::Base.connection.index_exists?(:streams, :status)).to be true
    end
    
    it 'has index on is_pinned' do
      expect(ActiveRecord::Base.connection.index_exists?(:streams, :is_pinned)).to be true
    end
    
    it 'has composite index on user_id and created_at' do
      expect(ActiveRecord::Base.connection.index_exists?(:streams, [:user_id, :created_at])).to be true
    end
  end
  
  describe 'edge cases' do
    it 'handles very long URLs' do
      stream = build(:stream, url: "https://example.com/#{'a' * 2000}")
      expect(stream).to be_valid
    end
    
    it 'handles URLs with special characters' do
      stream = build(:stream, url: 'https://example.com/path?q=test&foo=bar#anchor')
      expect(stream).to be_valid
    end
    
    it 'handles international domain names' do
      stream = build(:stream, url: 'https://例え.jp')
      stream.valid?
      # URL validation might fail for IDN, but shouldn't raise error
      expect { stream.valid? }.not_to raise_error
    end
  end
end