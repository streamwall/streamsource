require 'rails_helper'

RSpec.describe Stream, type: :model do
  describe 'Turbo Stream Broadcasting' do
    let(:user) { create(:user) }
    let(:stream) { build(:stream, user: user) }

    # For now, we'll just test that the callbacks are defined
    it 'has broadcasting callbacks defined' do
      callbacks = Stream._commit_callbacks.map(&:filter)
      
      expect(callbacks).to include(
        a_proc_containing("broadcast_prepend_later_to"),
        a_proc_containing("broadcast_replace_later_to"),
        a_proc_containing("broadcast_remove_to")
      )
    end

    # Test that streams can be created, updated, and destroyed without errors
    it 'creates without broadcasting errors' do
      expect { stream.save! }.not_to raise_error
    end

    it 'updates without broadcasting errors' do
      stream.save!
      expect { stream.update!(source: 'Updated Source') }.not_to raise_error
    end

    it 'destroys without broadcasting errors' do
      stream.save!
      expect { stream.destroy! }.not_to raise_error
    end
  end
end

# Custom matcher for checking proc content
RSpec::Matchers.define :a_proc_containing do |expected|
  match do |actual|
    actual.is_a?(Proc) && actual.source_location && 
    File.read(actual.source_location[0]).lines[actual.source_location[1] - 1].include?(expected)
  end
end