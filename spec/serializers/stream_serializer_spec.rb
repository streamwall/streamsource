require 'rails_helper'

RSpec.describe StreamSerializer do
  let(:user) { create(:user, :editor) }
  let(:stream) do
    create(:stream,
      user: user,
      source: 'Test Stream',
      link: 'https://example.com/stream',
      status: 'live',
      is_pinned: true
    )
  end
  let(:serializer) { described_class.new(stream, scope: scope) }
  let(:scope) { Api::V1::BaseController::SerializationScope.new(user) }
  let(:serialization) { ActiveModelSerializers::Adapter.create(serializer).as_json }
  
  describe 'attributes' do
    it 'includes id' do
      expect(serialization['id']).to eq(stream.id)
    end
    
    it 'includes link' do
      expect(serialization['link']).to eq('https://example.com/stream')
    end
    
    it 'includes source' do
      expect(serialization['source']).to eq('Test Stream')
    end
    
    it 'includes status' do
      expect(serialization['status']).to eq('live')
    end
    
    it 'includes is_pinned' do
      expect(serialization['is_pinned']).to be true
    end
    
    it 'includes created_at' do
      expect(serialization['created_at']).to be_present
    end
    
    it 'includes updated_at' do
      expect(serialization['updated_at']).to be_present
    end
    
    it 'includes platform' do
      expect(serialization['platform']).to be_present
    end
    
    it 'includes notes' do
      expect(serialization['notes']).to eq(stream.notes)
    end
    
    it 'includes title' do
      expect(serialization['title']).to eq(stream.title)
    end
  end
  
  describe 'associations' do
    it 'includes user association' do
      expect(serialization['user']).to be_present
      expect(serialization['user']['id']).to eq(user.id)
      expect(serialization['user']['email']).to eq(user.email)
      expect(serialization['user']['role']).to eq('editor')
    end
    
    it 'uses UserSerializer for user association' do
      user_serialization = serialization['user']
      expect(user_serialization).not_to have_key('password_digest')
      expect(user_serialization).to have_key('created_at')
      expect(user_serialization).to have_key('updated_at')
    end
  end
  
  describe 'feature flags' do
    context 'when analytics feature is enabled' do
      before do
        Flipper.enable(ApplicationConstants::Features::STREAM_ANALYTICS, user)
      end
      
      after do
        Flipper.disable(ApplicationConstants::Features::STREAM_ANALYTICS)
      end
      
      it 'includes analytics_url' do
        expect(serialization['analytics_url']).to eq("/api/v1/streams/#{stream.id}/analytics")
      end
    end
    
    context 'when analytics feature is disabled' do
      before do
        Flipper.disable(ApplicationConstants::Features::STREAM_ANALYTICS)
      end
      
      it 'does not include analytics_url' do
        expect(serialization).not_to have_key('analytics_url')
      end
    end
  end
  
  describe 'with different statuses' do
    it 'serializes offline streams correctly' do
      offline_stream = create(:stream, status: 'offline')
      serialization = JSON.parse(ActiveModelSerializers::Adapter.create(described_class.new(offline_stream, scope: scope)).to_json)
      
      expect(serialization['status']).to eq('offline')
    end
  end
  
  describe 'with unpinned streams' do
    it 'serializes unpinned streams correctly' do
      unpinned_stream = create(:stream, is_pinned: false)
      serialization = JSON.parse(ActiveModelSerializers::Adapter.create(described_class.new(unpinned_stream, scope: scope)).to_json)
      
      expect(serialization['is_pinned']).to be false
    end
  end
  
  describe 'collection serialization' do
    let(:streams) { create_list(:stream, 3, user: user) }
    let(:serializer) { ActiveModel::Serializer::CollectionSerializer.new(streams, serializer: described_class, scope: scope) }
    let(:collection_json) { JSON.parse(ActiveModelSerializers::Adapter.create(serializer).to_json) }
    
    it 'serializes multiple streams' do
      expect(collection_json).to be_an(Array)
      expect(collection_json.length).to eq(3)
    end
    
    it 'includes all attributes for each stream' do
      collection_json.each do |stream_json|
        expect(stream_json).to have_key('id')
        expect(stream_json).to have_key('link')
        expect(stream_json).to have_key('source')
        expect(stream_json).to have_key('status')
        expect(stream_json).to have_key('is_pinned')
        expect(stream_json).to have_key('user')
        expect(stream_json).to have_key('created_at')
        expect(stream_json).to have_key('updated_at')
      end
    end
  end
  
  describe 'edge cases' do
    it 'handles very long sources' do
      stream.source = 'A' * 255
      serialization = JSON.parse(ActiveModelSerializers::Adapter.create(described_class.new(stream, scope: scope)).to_json)
      
      expect(serialization['source']).to eq('A' * 255)
    end
    
    it 'handles special characters in link' do
      stream.link = 'https://example.com/stream?param=value&other=test%20space'
      serialization = JSON.parse(ActiveModelSerializers::Adapter.create(described_class.new(stream, scope: scope)).to_json)
      
      expect(serialization['link']).to eq(stream.link)
    end
  end
end