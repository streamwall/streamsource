require 'rails_helper'

RSpec.describe Admin::BaseController, type: :controller do
  controller do
    def index
      render plain: 'success'
    end
  end
  
  describe 'authentication' do
    context 'when admin user is logged in' do
      let(:admin_user) { create(:user, :admin) }
      
      before do
        allow(controller).to receive(:current_admin_user).and_return(admin_user)
      end
      
      it 'allows access' do
        get :index
        expect(response).to have_http_status(:success)
      end
    end
    
    context 'when no user is logged in' do
      before do
        allow(controller).to receive(:current_admin_user).and_return(nil)
      end
      
      it 'redirects to login' do
        get :index
        expect(response).to redirect_to(admin_login_path)
      end
    end
  end
  
  describe '#current_admin_user' do
    let(:admin_user) { create(:user, :admin) }
    
    it 'returns user from session' do
      session[:admin_user_id] = admin_user.id
      expect(controller.send(:current_admin_user)).to eq(admin_user)
    end
    
    it 'returns nil when no session' do
      session[:admin_user_id] = nil
      expect(controller.send(:current_admin_user)).to be_nil
    end
    
    it 'returns nil when user not found' do
      session[:admin_user_id] = 999999
      expect(controller.send(:current_admin_user)).to be_nil
    end
  end
end