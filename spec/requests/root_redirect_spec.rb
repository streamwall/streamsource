require 'rails_helper'

RSpec.describe "Root redirect", type: :request do
  describe "GET /" do
    it "redirects to API docs" do
      get "/"
      expect(response).to redirect_to("/api-docs")
    end
  end
end