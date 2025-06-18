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
  let(:serializer) { described_class.new(stream) }
  let(:serialization) { ActiveModelSerializers::Adapter.create(serializer).as_json[:stream] }
  
  describe 'attributes' do
    it 'includes id' do
      expect(serialization[:id]).to eq(stream.id)
    end
    
    it 'includes link' do
      expect(serialization[:link]).to eq('https://example.com/stream')
    end
    
    it 'includes source' do
      expect(serialization[:source]).to eq('Test Stream')
    end
    
    it 'includes status' do
      expect(serialization[:status]).to eq('live')
    end
    
    it 'includes is_pinned' do
      expect(serialization[:is_pinned]).to be true
    end
    
    it 'includes created_at' do
      expect(serialization[:created_at].iso8601(3)).to eq(stream.created_at.iso8601(3))
    end
    
    it 'includes updated_at' do
      expect(serialization[:updated_at].iso8601(3)).to eq(stream.updated_at.iso8601(3))
    end
  end
  
  describe 'associations' do
    it 'includes user association' do
      expect(serialization[:user]).to be_present
      expect(serialization[:user][:id]).to eq(user.id)
      expect(serialization[:user][:email]).to eq(user.email)
      expect(serialization[:user][:role]).to eq('editor')
    end
    
    it 'uses UserSerializer for user association' do
      user_serialization = serialization[:user]
      expect(user_serialization).not_to have_key(:password_digest)
      expect(user_serialization).to have_key(:created_at)
      expect(user_serialization).to have_key(:updated_at)
    end
  end
  
  describe 'with different statuses' do
    it 'serializes offline streams correctly' do
      offline_stream = create(:stream, status: 'offline')
      serialization = ActiveModelSerializers::Adapter.create(described_class.new(offline_stream)).as_json[:stream]
      
      expect(serialization[:status]).to eq('offline')
    end
  end
  
  describe 'with unpinned streams' do
    it 'serializes unpinned streams correctly' do
      unpinned_stream = create(:stream, is_pinned: false)
      serialization = ActiveModelSerializers::Adapter.create(described_class.new(unpinned_stream)).as_json[:stream]
      
      expect(serialization[:is_pinned]).to be false
    end
  end
  
  describe 'collection serialization' do
    let(:streams) { create_list(:stream, 3, user: user) }
    let(:serializer) { ActiveModel::Serializer::CollectionSerializer.new(streams, serializer: described_class) }
    let(:serialization) { ActiveModelSerializers::Adapter.create(serializer).as_json[:streams] }
    
    it 'serializes multiple streams' do
      expect(serialization).to be_an(Array)
      expect(serialization.length).to eq(3)
    end
    
    it 'includes all attributes for each stream' do
      serialization.each do |stream_json|
        expect(stream_json).to have_key(:id)
        expect(stream_json).to have_key(:link)
        expect(stream_json).to have_key(:source)
        expect(stream_json).to have_key(:status)
        expect(stream_json).to have_key(:is_pinned)
        expect(stream_json).to have_key(:user)
        expect(stream_json).to have_key(:created_at)
        expect(stream_json).to have_key(:updated_at)
      end
    end
  end
  
  describe 'edge cases' do
    it 'handles very long sources' do
      stream.source = 'A' * 255
      serialization = ActiveModelSerializers::Adapter.create(described_class.new(stream)).as_json[:stream]
      
      expect(serialization[:source]).to eq('A' * 255)
    end
    
    it 'handles special characters in link' do
      stream.link = 'https://example.com/stream?param=value&other=test%20space'
      serialization = ActiveModelSerializers::Adapter.create(described_class.new(stream)).as_json[:stream]
      
      expect(serialization[:link]).to eq(stream.link)
    end
  end
end