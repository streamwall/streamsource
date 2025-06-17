require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  describe 'included concerns' do
    it 'includes JwtAuthenticatable' do
      expect(ApplicationController.ancestors).to include(JwtAuthenticatable)
    end
  end
  
  describe 'maintenance mode' do
    controller do
      skip_before_action :authenticate_user!
      
      def index
        render json: { message: 'test' }
      end
    end
    
    context 'when maintenance mode is enabled' do
      before do
        allow(Flipper).to receive(:enabled?).with(ApplicationConstants::Features::MAINTENANCE_MODE).and_return(true)
      end
      
      it 'returns service unavailable' do
        get :index
        expect(response).to have_http_status(:service_unavailable)
        expect(JSON.parse(response.body)['error']).to include('maintenance')
      end
    end
    
    context 'when maintenance mode is disabled' do
      before do
        allow(Flipper).to receive(:enabled?).with(ApplicationConstants::Features::MAINTENANCE_MODE).and_return(false)
      end
      
      it 'allows normal requests' do
        get :index
        expect(response).to have_http_status(:ok)
      end
    end
  end
end