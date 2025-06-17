require 'rails_helper'

RSpec.describe Admin::SessionsController, type: :controller do
  describe 'GET #new' do
    it 'returns success' do
      get :new
      expect(response).to have_http_status(:success)
    end
    
    it 'renders the new template' do
      get :new
      expect(response).to render_template(:new)
    end
  end
  
  describe 'POST #create' do
    let(:admin_user) { create(:user, :admin, email: 'admin@example.com', password: 'Password123!') }
    
    context 'with valid credentials' do
      it 'sets session' do
        post :create, params: { email: admin_user.email, password: 'Password123!' }
        expect(session[:admin_user_id]).to eq(admin_user.id)
      end
      
      it 'redirects to admin root' do
        post :create, params: { email: admin_user.email, password: 'Password123!' }
        expect(response).to redirect_to(admin_streams_path)
      end
      
      it 'sets success notice' do
        post :create, params: { email: admin_user.email, password: 'Password123!' }
        expect(flash[:notice]).to eq('Successfully logged in.')
      end
    end
    
    context 'with invalid credentials' do
      it 'does not set session' do
        post :create, params: { email: admin_user.email, password: 'wrong' }
        expect(session[:admin_user_id]).to be_nil
      end
      
      it 'renders new template' do
        post :create, params: { email: admin_user.email, password: 'wrong' }
        expect(response).to render_template(:new)
      end
      
      it 'sets alert message' do
        post :create, params: { email: admin_user.email, password: 'wrong' }
        expect(flash[:alert]).to eq('Invalid email or password, or insufficient privileges.')
      end
    end
    
    context 'with non-existent user' do
      it 'renders new template' do
        post :create, params: { email: 'nonexistent@example.com', password: 'Password123!' }
        expect(response).to render_template(:new)
      end
      
      it 'sets alert message' do
        post :create, params: { email: 'nonexistent@example.com', password: 'Password123!' }
        expect(flash[:alert]).to eq('Invalid email or password, or insufficient privileges.')
      end
    end
    
    context 'with non-admin user' do
      let(:regular_user) { create(:user, email: 'user@example.com', password: 'Password123!') }
      
      it 'does not set session' do
        post :create, params: { email: regular_user.email, password: 'Password123!' }
        expect(session[:admin_user_id]).to be_nil
      end
      
      it 'renders new template' do
        post :create, params: { email: regular_user.email, password: 'Password123!' }
        expect(response).to render_template(:new)
      end
      
      it 'sets alert message' do
        post :create, params: { email: regular_user.email, password: 'Password123!' }
        expect(flash[:alert]).to eq('Invalid email or password, or insufficient privileges.')
      end
    end
  end
  
  describe 'DELETE #destroy' do
    let(:admin_user) { create(:user, :admin) }
    
    before do
      session[:admin_user_id] = admin_user.id
    end
    
    it 'clears session' do
      delete :destroy
      expect(session[:admin_user_id]).to be_nil
    end
    
    it 'redirects to login' do
      delete :destroy
      expect(response).to redirect_to(admin_login_path)
    end
    
    it 'sets notice' do
      delete :destroy
      expect(flash[:notice]).to eq('Successfully logged out.')
    end
  end
end