require 'rails_helper'

RSpec.describe StreamerAccount, 'instance methods', type: :model do
  let(:account) { create(:streamer_account) }
  
  describe '#activate!' do
    context 'when account is inactive' do
      before { account.update(is_active: false) }
      
      it 'sets is_active to true' do
        expect { account.activate! }.to change { account.is_active }.from(false).to(true)
      end
    end
    
    context 'when account is already active' do
      before { account.update(is_active: true) }
      
      it 'keeps is_active as true' do
        account.activate!
        expect(account.is_active).to be true
      end
    end
  end
  
  describe '#deactivate!' do
    context 'when account is active' do
      before { account.update(is_active: true) }
      
      it 'sets is_active to false' do
        expect { account.deactivate! }.to change { account.is_active }.from(true).to(false)
      end
    end
    
    context 'when account is already inactive' do
      before { account.update(is_active: false) }
      
      it 'keeps is_active as false' do
        account.deactivate!
        expect(account.is_active).to be false
      end
    end
  end
end