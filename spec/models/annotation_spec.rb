require 'rails_helper'

RSpec.describe Annotation, type: :model do
  subject { build(:annotation) }
  
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:resolved_by_user).class_name('User').optional }
    it { should have_many(:annotation_streams).dependent(:destroy) }
    it { should have_many(:streams).through(:annotation_streams) }
    it { should have_many(:notes).dependent(:destroy) }
  end
  
  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_length_of(:title).is_at_least(3).is_at_most(200) }
    it { should validate_length_of(:description).is_at_most(2000) }
    it { should validate_presence_of(:event_timestamp) }
    it { should validate_length_of(:location).is_at_most(100) }
    
    it 'validates latitude range' do
      annotation = build(:annotation, latitude: 91)
      expect(annotation).not_to be_valid
      expect(annotation.errors[:latitude]).to include('must be less than or equal to 90')
      
      annotation.latitude = -91
      expect(annotation).not_to be_valid
      expect(annotation.errors[:latitude]).to include('must be greater than or equal to -90')
      
      annotation.latitude = 40.7128
      expect(annotation).to be_valid
    end
    
    it 'validates longitude range' do
      annotation = build(:annotation, longitude: 181)
      expect(annotation).not_to be_valid
      expect(annotation.errors[:longitude]).to include('must be less than or equal to 180')
      
      annotation.longitude = -181
      expect(annotation).not_to be_valid
      expect(annotation.errors[:longitude]).to include('must be greater than or equal to -180')
      
      annotation.longitude = -74.0060
      expect(annotation).to be_valid
    end
    
    it 'validates external_url format' do
      annotation = build(:annotation, external_url: 'not-a-url')
      expect(annotation).not_to be_valid
      expect(annotation.errors[:external_url]).to include('is invalid')
      
      annotation.external_url = 'https://example.com/article'
      expect(annotation).to be_valid
    end
    
    it 'allows blank external_url' do
      annotation = build(:annotation, external_url: '')
      expect(annotation).to be_valid
    end
  end
  
  describe 'enums' do
    it { should define_enum_for(:event_type).with_values(
      breaking_news: 'breaking_news',
      emergency: 'emergency',
      protest: 'protest',
      incident: 'incident',
      celebrity_sighting: 'celebrity_sighting',
      sports_event: 'sports_event',
      weather_event: 'weather_event',
      political_event: 'political_event',
      cultural_event: 'cultural_event',
      traffic_incident: 'traffic_incident',
      content_flag: 'content_flag',
      technical_outage: 'technical_outage',
      viral_moment: 'viral_moment',
      coordinated_action: 'coordinated_action',
      other: 'other'
    ).with_prefix(true) }
    
    it { should define_enum_for(:priority_level).with_values(
      low: 'low',
      medium: 'medium',
      high: 'high',
      critical: 'critical'
    ).with_prefix(true) }
    
    it { should define_enum_for(:review_status).with_values(
      pending: 'pending',
      in_review: 'in_review',
      reviewed: 'reviewed',
      resolved: 'resolved',
      dismissed: 'dismissed'
    ).with_prefix(true) }
  end
  
  describe 'scopes' do
    let!(:user) { create(:user) }
    let!(:critical_annotation) { create(:annotation, user: user, priority_level: 'critical') }
    let!(:high_annotation) { create(:annotation, user: user, priority_level: 'high') }
    let!(:pending_annotation) { create(:annotation, user: user, review_status: 'pending') }
    let!(:resolved_annotation) { create(:annotation, user: user, review_status: 'resolved', resolved_at: 1.day.ago) }
    let!(:today_annotation) { create(:annotation, user: user, event_timestamp: Time.current) }
    let!(:old_annotation) { create(:annotation, user: user, event_timestamp: 2.weeks.ago) }
    
    describe '.recent' do
      it 'orders by event_timestamp descending' do
        expect(Annotation.recent.first).to eq(today_annotation)
        expect(Annotation.recent.last).to eq(old_annotation)
      end
    end
    
    describe '.critical_and_high' do
      it 'returns only critical and high priority annotations' do
        expect(Annotation.critical_and_high).to contain_exactly(critical_annotation, high_annotation)
      end
    end
    
    describe '.unresolved' do
      it 'excludes resolved and dismissed annotations' do
        dismissed = create(:annotation, user: user, review_status: 'dismissed')
        expect(Annotation.unresolved).not_to include(resolved_annotation, dismissed)
        expect(Annotation.unresolved).to include(pending_annotation, critical_annotation)
      end
    end
    
    describe '.occurred_today' do
      it 'returns annotations from today' do
        expect(Annotation.occurred_today).to include(today_annotation)
        expect(Annotation.occurred_today).not_to include(old_annotation)
      end
    end
    
    describe '.near_location' do
      let!(:ny_annotation) { create(:annotation, user: user, latitude: 40.7128, longitude: -74.0060) }
      let!(:la_annotation) { create(:annotation, user: user, latitude: 34.0522, longitude: -118.2437) }
      
      it 'finds annotations within radius' do
        # Search near NYC
        nearby = Annotation.near_location(40.7580, -73.9855, 10) # Times Square
        expect(nearby).to include(ny_annotation)
        expect(nearby).not_to include(la_annotation)
      end
    end
    
    describe '.filtered' do
      it 'filters by multiple parameters' do
        filtered = Annotation.filtered(
          event_type: 'breaking_news',
          priority_level: 'critical',
          review_status: 'pending'
        )
        
        expect(filtered).to all(
          have_attributes(
            event_type: 'breaking_news',
            priority_level: 'critical',
            review_status: 'pending'
          )
        )
      end
      
      it 'filters by search term' do
        searchable = create(:annotation, user: user, title: 'Major earthquake', description: 'Significant damage')
        filtered = Annotation.filtered(search: 'earthquake')
        expect(filtered).to include(searchable)
      end
    end
  end
  
  describe 'callbacks' do
    describe '#auto_flag_for_review' do
      it 'sets requires_review for critical priority' do
        annotation = build(:annotation, priority_level: 'critical', requires_review: false)
        annotation.save!
        expect(annotation.requires_review).to be true
      end
      
      it 'sets requires_review for emergency type' do
        annotation = build(:annotation, event_type: 'emergency', requires_review: false)
        annotation.save!
        expect(annotation.requires_review).to be true
      end
      
      it 'sets requires_review for content_flag type' do
        annotation = build(:annotation, event_type: 'content_flag', requires_review: false)
        annotation.save!
        expect(annotation.requires_review).to be true
      end
    end
  end
  
  describe 'instance methods' do
    let(:user) { create(:user) }
    let(:admin) { create(:user, :admin) }
    let(:annotation) { create(:annotation, user: user) }
    
    describe '#owned_by?' do
      it 'returns true for owner' do
        expect(annotation.owned_by?(user)).to be true
      end
      
      it 'returns false for non-owner' do
        expect(annotation.owned_by?(admin)).to be false
      end
      
      it 'returns false for nil user' do
        expect(annotation.owned_by?(nil)).to be false
      end
    end
    
    describe '#resolved?' do
      it 'returns true when resolved' do
        annotation.resolve!(admin)
        expect(annotation.resolved?).to be true
      end
      
      it 'returns false when not resolved' do
        expect(annotation.resolved?).to be false
      end
    end
    
    describe '#needs_attention?' do
      it 'returns true for critical priority' do
        annotation.update!(priority_level: 'critical')
        expect(annotation.needs_attention?).to be true
      end
      
      it 'returns true when requires_review' do
        annotation.update!(requires_review: true)
        expect(annotation.needs_attention?).to be true
      end
    end
    
    describe '#resolve!' do
      it 'updates status and tracking fields' do
        annotation.resolve!(admin, 'All good')
        expect(annotation.review_status).to eq('resolved')
        expect(annotation.resolved_at).to be_present
        expect(annotation.resolved_by_user).to eq(admin)
        expect(annotation.resolution_notes).to eq('All good')
      end
    end
    
    describe '#dismiss!' do
      it 'updates status to dismissed' do
        annotation.dismiss!(admin, 'False alarm')
        expect(annotation.review_status).to eq('dismissed')
        expect(annotation.resolved_at).to be_present
        expect(annotation.resolved_by_user).to eq(admin)
        expect(annotation.resolution_notes).to eq('False alarm')
      end
    end
    
    describe '#add_stream!' do
      let(:stream) { create(:stream) }
      
      it 'creates annotation_stream association' do
        expect {
          annotation.add_stream!(stream, user, timestamp_seconds: 120, relevance: 4)
        }.to change { annotation.annotation_streams.count }.by(1)
        
        annotation_stream = annotation.annotation_streams.last
        expect(annotation_stream.stream).to eq(stream)
        expect(annotation_stream.added_by_user).to eq(user)
        expect(annotation_stream.stream_timestamp_seconds).to eq(120)
        expect(annotation_stream.relevance_score).to eq(4)
      end
    end
    
    describe '#tag_list' do
      it 'handles JSON array format' do
        annotation.tags = ['breaking', 'urgent'].to_json
        expect(annotation.tag_list).to eq(['breaking', 'urgent'])
      end
      
      it 'handles comma-separated format' do
        annotation.tags = 'breaking, urgent, news'
        expect(annotation.tag_list).to eq(['breaking', 'urgent', 'news'])
      end
      
      it 'returns empty array for blank tags' do
        annotation.tags = nil
        expect(annotation.tag_list).to eq([])
      end
    end
    
    describe '#tag_list=' do
      it 'accepts array of tags' do
        annotation.tag_list = ['breaking', 'urgent']
        expect(JSON.parse(annotation.tags)).to eq(['breaking', 'urgent'])
      end
      
      it 'accepts comma-separated string' do
        annotation.tag_list = 'breaking, urgent, news'
        expect(JSON.parse(annotation.tags)).to eq(['breaking', 'urgent', 'news'])
      end
      
      it 'filters blank tags' do
        annotation.tag_list = ['breaking', '', 'urgent', nil]
        expect(JSON.parse(annotation.tags)).to eq(['breaking', 'urgent'])
      end
    end
    
    describe '#priority_color' do
      it 'returns correct color classes' do
        annotation.priority_level = 'critical'
        expect(annotation.priority_color).to eq('text-red-600 bg-red-100')
        
        annotation.priority_level = 'high'
        expect(annotation.priority_color).to eq('text-orange-600 bg-orange-100')
        
        annotation.priority_level = 'medium'
        expect(annotation.priority_color).to eq('text-yellow-600 bg-yellow-100')
        
        annotation.priority_level = 'low'
        expect(annotation.priority_color).to eq('text-gray-600 bg-gray-100')
      end
    end
    
    describe '#status_color' do
      it 'returns correct color classes' do
        annotation.review_status = 'pending'
        expect(annotation.status_color).to eq('text-yellow-600 bg-yellow-100')
        
        annotation.review_status = 'resolved'
        expect(annotation.status_color).to eq('text-green-600 bg-green-100')
        
        annotation.review_status = 'dismissed'
        expect(annotation.status_color).to eq('text-gray-600 bg-gray-100')
      end
    end
  end
  
  describe 'database indexes' do
    it 'has required indexes' do
      expect(ActiveRecord::Base.connection.index_exists?(:annotations, :event_timestamp)).to be true
      expect(ActiveRecord::Base.connection.index_exists?(:annotations, :event_type)).to be true
      expect(ActiveRecord::Base.connection.index_exists?(:annotations, :priority_level)).to be true
      expect(ActiveRecord::Base.connection.index_exists?(:annotations, :review_status)).to be true
      expect(ActiveRecord::Base.connection.index_exists?(:annotations, :requires_review)).to be true
      expect(ActiveRecord::Base.connection.index_exists?(:annotations, [:event_timestamp, :priority_level])).to be true
    end
  end
end