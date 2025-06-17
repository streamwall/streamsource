require 'rails_helper'

RSpec.describe AnnotationStream, type: :model do
  subject { build(:annotation_stream) }
  
  describe 'associations' do
    it { should belong_to(:annotation) }
    it { should belong_to(:stream) }
    it { should belong_to(:added_by_user).class_name('User') }
  end
  
  describe 'validations' do
    it { should validate_inclusion_of(:relevance_score).in_array([1, 2, 3, 4, 5]) }
    it { should validate_numericality_of(:stream_timestamp_seconds).is_greater_than_or_equal_to(0).allow_nil(true) }
    it { should validate_length_of(:stream_notes).is_at_most(1000) }
  end
  
  describe 'scopes' do
    let!(:user) { create(:user) }
    let!(:annotation) { create(:annotation, user: user) }
    let!(:stream) { create(:stream) }
    let!(:high_relevance) { create(:annotation_stream, annotation: annotation, stream: stream, relevance_score: 5) }
    let!(:low_relevance) { create(:annotation_stream, annotation: annotation, stream: create(:stream), relevance_score: 2) }
    let!(:with_timestamp) { create(:annotation_stream, annotation: annotation, stream: create(:stream), stream_timestamp_seconds: 120) }
    let!(:without_timestamp) { create(:annotation_stream, annotation: annotation, stream: create(:stream), stream_timestamp_seconds: nil) }
    
    describe '.by_relevance' do
      it 'orders by relevance_score descending' do
        expect(AnnotationStream.by_relevance.first).to eq(high_relevance)
        expect(AnnotationStream.by_relevance.last.relevance_score).to be <= 3
      end
    end
    
    describe '.high_relevance' do
      it 'returns only annotations with relevance 4 or 5' do
        expect(AnnotationStream.high_relevance).to include(high_relevance)
        expect(AnnotationStream.high_relevance).not_to include(low_relevance)
      end
    end
    
    describe '.with_timestamp' do
      it 'returns only annotations with timestamps' do
        expect(AnnotationStream.with_timestamp).to include(with_timestamp)
        expect(AnnotationStream.with_timestamp).not_to include(without_timestamp)
      end
    end
  end
  
  describe 'callbacks' do
    describe '#generate_timestamp_display' do
      it 'generates display format on save' do
        annotation_stream = build(:annotation_stream, stream_timestamp_seconds: 3665)
        annotation_stream.save!
        expect(annotation_stream.stream_timestamp_display).to eq('1:01:05')
      end
      
      it 'does not generate if timestamp is nil' do
        annotation_stream = build(:annotation_stream, stream_timestamp_seconds: nil)
        annotation_stream.save!
        expect(annotation_stream.stream_timestamp_display).to be_nil
      end
    end
  end
  
  describe 'instance methods' do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let(:annotation_stream) { create(:annotation_stream, added_by_user: user) }
    
    describe '#added_by?' do
      it 'returns true for the user who added it' do
        expect(annotation_stream.added_by?(user)).to be true
      end
      
      it 'returns false for other users' do
        expect(annotation_stream.added_by?(other_user)).to be false
      end
      
      it 'returns false for nil user' do
        expect(annotation_stream.added_by?(nil)).to be false
      end
    end
    
    describe '#formatted_stream_timestamp' do
      it 'formats hours:minutes:seconds for long durations' do
        annotation_stream.stream_timestamp_seconds = 3665
        expect(annotation_stream.formatted_stream_timestamp).to eq('1:01:05')
      end
      
      it 'formats minutes:seconds for short durations' do
        annotation_stream.stream_timestamp_seconds = 125
        expect(annotation_stream.formatted_stream_timestamp).to eq('2:05')
      end
      
      it 'handles zero seconds' do
        annotation_stream.stream_timestamp_seconds = 0
        expect(annotation_stream.formatted_stream_timestamp).to eq('0:00')
      end
      
      it 'returns saved display format if available' do
        annotation_stream.stream_timestamp_display = 'Custom Format'
        expect(annotation_stream.formatted_stream_timestamp).to eq('Custom Format')
      end
      
      it 'returns Unknown for nil timestamp' do
        annotation_stream.stream_timestamp_seconds = nil
        expect(annotation_stream.formatted_stream_timestamp).to eq('Unknown')
      end
    end
    
    describe '#relevance_description' do
      it 'returns correct descriptions' do
        annotation_stream.relevance_score = 5
        expect(annotation_stream.relevance_description).to eq('Primary source')
        
        annotation_stream.relevance_score = 4
        expect(annotation_stream.relevance_description).to eq('High relevance')
        
        annotation_stream.relevance_score = 3
        expect(annotation_stream.relevance_description).to eq('Moderate relevance')
        
        annotation_stream.relevance_score = 2
        expect(annotation_stream.relevance_description).to eq('Low relevance')
        
        annotation_stream.relevance_score = 1
        expect(annotation_stream.relevance_description).to eq('Background/context')
      end
    end
    
    describe '#relevance_color' do
      it 'returns correct color classes' do
        annotation_stream.relevance_score = 5
        expect(annotation_stream.relevance_color).to eq('text-green-700 bg-green-100')
        
        annotation_stream.relevance_score = 4
        expect(annotation_stream.relevance_color).to eq('text-blue-700 bg-blue-100')
        
        annotation_stream.relevance_score = 3
        expect(annotation_stream.relevance_color).to eq('text-yellow-700 bg-yellow-100')
        
        annotation_stream.relevance_score = 2
        expect(annotation_stream.relevance_color).to eq('text-orange-700 bg-orange-100')
        
        annotation_stream.relevance_score = 1
        expect(annotation_stream.relevance_color).to eq('text-gray-700 bg-gray-100')
      end
    end
  end
  
  describe 'uniqueness constraint' do
    it 'prevents duplicate annotation-stream pairs' do
      annotation = create(:annotation)
      stream = create(:stream)
      create(:annotation_stream, annotation: annotation, stream: stream)
      
      duplicate = build(:annotation_stream, annotation: annotation, stream: stream)
      expect(duplicate).not_to be_valid
      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
  
  describe 'database indexes' do
    it 'has required indexes' do
      expect(ActiveRecord::Base.connection.index_exists?(:annotation_streams, [:annotation_id, :stream_id])).to be true
      expect(ActiveRecord::Base.connection.index_exists?(:annotation_streams, :stream_id)).to be true
      expect(ActiveRecord::Base.connection.index_exists?(:annotation_streams, :stream_timestamp_seconds)).to be true
      expect(ActiveRecord::Base.connection.index_exists?(:annotation_streams, :relevance_score)).to be true
    end
  end
end