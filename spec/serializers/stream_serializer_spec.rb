require 'rails_helper'

RSpec.describe StreamSerializer do
  let(:user) { create(:user, :editor) }
  let(:stream) do
    create(:stream,
      user: user,
      name: 'Test Stream',
      url: 'https://example.com/stream',
      status: 'active',
      is_pinned: true
    )
  end
  let(:serializer) { described_class.new(stream) }
  let(:serialization) { ActiveModelSerializers::Adapter.create(serializer).as_json }
  
  describe 'attributes' do
    it 'includes id' do
      expect(serialization[:id]).to eq(stream.id)
    end
    
    it 'includes url' do
      expect(serialization[:url]).to eq('https://example.com/stream')
    end
    
    it 'includes name' do
      expect(serialization[:name]).to eq('Test Stream')
    end
    
    it 'includes status' do
      expect(serialization[:status]).to eq('active')
    end
    
    it 'includes is_pinned' do
      expect(serialization[:is_pinned]).to be true
    end
    
    it 'includes created_at' do
      expect(serialization[:created_at]).to eq(stream.created_at.as_json)
    end
    
    it 'includes updated_at' do
      expect(serialization[:updated_at]).to eq(stream.updated_at.as_json)
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
    it 'serializes inactive streams correctly' do
      inactive_stream = create(:stream, status: 'inactive')
      serialization = ActiveModelSerializers::Adapter.create(described_class.new(inactive_stream)).as_json
      
      expect(serialization[:status]).to eq('inactive')
    end
  end
  
  describe 'with unpinned streams' do
    it 'serializes unpinned streams correctly' do
      unpinned_stream = create(:stream, is_pinned: false)
      serialization = ActiveModelSerializers::Adapter.create(described_class.new(unpinned_stream)).as_json
      
      expect(serialization[:is_pinned]).to be false
    end
  end
  
  describe 'collection serialization' do
    let(:streams) { create_list(:stream, 3, user: user) }
    let(:serializer) { ActiveModel::Serializer::CollectionSerializer.new(streams, serializer: described_class) }
    let(:serialization) { ActiveModelSerializers::Adapter.create(serializer).as_json }
    
    it 'serializes multiple streams' do
      expect(serialization).to be_an(Array)
      expect(serialization.length).to eq(3)
    end
    
    it 'includes all attributes for each stream' do
      serialization.each do |stream_json|
        expect(stream_json).to have_key(:id)
        expect(stream_json).to have_key(:url)
        expect(stream_json).to have_key(:name)
        expect(stream_json).to have_key(:status)
        expect(stream_json).to have_key(:is_pinned)
        expect(stream_json).to have_key(:user)
        expect(stream_json).to have_key(:created_at)
        expect(stream_json).to have_key(:updated_at)
      end
    end
  end
  
  describe 'edge cases' do
    it 'handles very long names' do
      stream.name = 'A' * 255
      serialization = ActiveModelSerializers::Adapter.create(described_class.new(stream)).as_json
      
      expect(serialization[:name]).to eq('A' * 255)
    end
    
    it 'handles special characters in URL' do
      stream.url = 'https://example.com/stream?param=value&other=test%20space'
      serialization = ActiveModelSerializers::Adapter.create(described_class.new(stream)).as_json
      
      expect(serialization[:url]).to eq(stream.url)
    end
  end
end