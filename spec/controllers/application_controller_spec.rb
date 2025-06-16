require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  controller do
    def index
      render json: { message: 'test' }
    end
  end
  
  describe 'error handling' do
    controller do
      def index
        raise ActiveRecord::RecordNotFound
      end
    end
    
    it 'handles RecordNotFound errors' do
      get :index
      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)['error']).to eq('Record not found')
    end
  end
  
  describe 'included concerns' do
    it 'includes JwtAuthenticatable' do
      expect(ApplicationController.ancestors).to include(JwtAuthenticatable)
    end
  end
end