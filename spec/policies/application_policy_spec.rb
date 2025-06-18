require 'rails_helper'

RSpec.describe ApplicationPolicy do
  let(:user) { create(:user) }
  let(:record) { double('record') }
  let(:policy) { described_class.new(user, record) }
  
  describe '#index?' do
    it 'returns true by default' do
      expect(policy.index?).to be true
    end
  end
  
  describe '#show?' do
    it 'returns true by default' do
      expect(policy.show?).to be true
    end
  end
  
  describe '#create?' do
    it 'returns false by default' do
      expect(policy.create?).to be false
    end
  end
  
  describe '#new?' do
    it 'delegates to create?' do
      expect(policy).to receive(:create?).and_return(true)
      expect(policy.new?).to be true
    end
  end
  
  describe '#update?' do
    it 'returns false by default' do
      expect(policy.update?).to be false
    end
  end
  
  describe '#edit?' do
    it 'delegates to update?' do
      expect(policy).to receive(:update?).and_return(true)
      expect(policy.edit?).to be true
    end
  end
  
  describe '#destroy?' do
    it 'returns false by default' do
      expect(policy.destroy?).to be false
    end
  end
  
  describe 'Scope' do
    let(:scope) { double('scope') }
    let(:policy_scope) { described_class::Scope.new(user, scope) }
    
    describe '#resolve' do
      it 'raises NotImplementedError' do
        expect { policy_scope.resolve }.to raise_error(NotImplementedError)
      end
    end
  end
  
  describe 'initialization' do
    it 'sets user and record' do
      expect(policy.user).to eq(user)
      expect(policy.record).to eq(record)
    end
    
    it 'handles nil user' do
      policy = described_class.new(nil, record)
      expect(policy.user).to be_nil
    end
  end
end