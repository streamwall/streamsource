# Shared examples for authorization patterns

RSpec.shared_examples "requires authentication" do |method, action, params = {}|
  it "returns unauthorized without authentication" do
    send(method, action, params: params)
    expect(response).to have_http_status(:unauthorized)
  end
end

RSpec.shared_examples "requires admin role" do |method, action, params = {}|
  let(:default_user) { create(:user, role: 'default') }
  let(:editor_user) { create(:user, role: 'editor') }
  
  it "returns forbidden for default users" do
    request.headers.merge!(auth_headers(default_user))
    send(method, action, params: params)
    expect(response).to have_http_status(:forbidden)
  end
  
  it "returns forbidden for editor users" do
    request.headers.merge!(auth_headers(editor_user))
    send(method, action, params: params)
    expect(response).to have_http_status(:forbidden)
  end
end

RSpec.shared_examples "requires editor role" do |method, action, params = {}|
  let(:default_user) { create(:user, role: 'default') }
  
  it "returns forbidden for default users" do
    request.headers.merge!(auth_headers(default_user))
    send(method, action, params: params)
    expect(response).to have_http_status(:forbidden)
  end
end

RSpec.shared_examples "allows admin access" do |method, action, params = {}|
  let(:admin_user) { create(:user, :admin) }
  
  it "allows admin users" do
    request.headers.merge!(auth_headers(admin_user))
    send(method, action, params: params)
    expect(response).not_to have_http_status(:forbidden)
    expect(response).not_to have_http_status(:unauthorized)
  end
end

RSpec.shared_examples "admin crud authorization" do
  let(:admin_user) { create(:user, :admin) }
  
  before { setup_admin_auth(admin_user) }
  
  context "when not authenticated" do
    before do
      allow_any_instance_of(Admin::BaseController).to receive(:authenticate_admin!).and_call_original
      allow_any_instance_of(Admin::BaseController).to receive(:current_admin_user).and_return(nil)
    end
    
    it "redirects to login for index" do
      get index_path
      expect(response).to redirect_to(admin_login_path)
    end
    
    it "redirects to login for show" do
      get show_path
      expect(response).to redirect_to(admin_login_path)
    end if defined?(show_path)
    
    it "redirects to login for new" do
      get new_path
      expect(response).to redirect_to(admin_login_path)
    end if defined?(new_path)
    
    it "redirects to login for create" do
      post create_path, params: valid_params
      expect(response).to redirect_to(admin_login_path)
    end if defined?(create_path)
  end
end

RSpec.shared_examples "api crud authorization" do |resource_name|
  let(:admin) { create(:user, :admin) }
  let(:editor) { create(:user, :editor) }
  let(:default_user) { create(:user, :default) }
  let(:resource) { create(resource_name, user: editor) }
  
  describe "index" do
    it_behaves_like "requires authentication", :get, :index
    
    it "allows authenticated users" do
      request.headers.merge!(auth_headers(default_user))
      get :index
      expect(response).to have_http_status(:success)
    end
  end
  
  describe "show" do
    it_behaves_like "requires authentication", :get, :show, { id: 1 }
    
    it "allows authenticated users" do
      request.headers.merge!(auth_headers(default_user))
      get :show, params: { id: resource.id }
      expect(response).to have_http_status(:success)
    end
  end
  
  describe "create" do
    it_behaves_like "requires authentication", :post, :create
    it_behaves_like "requires editor role", :post, :create, { source: 'Test', link: 'https://example.com' }
    
    it "allows editors" do
      request.headers.merge!(auth_headers(editor))
      post :create, params: { source: 'Test', link: 'https://example.com' }
      expect(response).to have_http_status(:created)
    end
  end
  
  describe "update" do
    it_behaves_like "requires authentication", :patch, :update, { id: 1 }
    
    context "as resource owner" do
      it "allows update" do
        request.headers.merge!(auth_headers(editor))
        patch :update, params: { id: resource.id, source: 'Updated' }
        expect(response).to have_http_status(:success)
      end
    end
    
    context "as non-owner" do
      let(:other_editor) { create(:user, :editor) }
      
      it "denies update" do
        request.headers.merge!(auth_headers(other_editor))
        patch :update, params: { id: resource.id, source: 'Updated' }
        expect(response).to have_http_status(:forbidden)
      end
    end
    
    context "as admin" do
      it "allows update" do
        request.headers.merge!(auth_headers(admin))
        patch :update, params: { id: resource.id, source: 'Updated' }
        expect(response).to have_http_status(:success)
      end
    end
  end
  
  describe "destroy" do
    it_behaves_like "requires authentication", :delete, :destroy, { id: 1 }
    
    context "as resource owner" do
      it "allows destroy" do
        request.headers.merge!(auth_headers(editor))
        delete :destroy, params: { id: resource.id }
        expect(response).to have_http_status(:no_content)
      end
    end
    
    context "as non-owner" do
      it "denies destroy" do
        request.headers.merge!(auth_headers(default_user))
        delete :destroy, params: { id: resource.id }
        expect(response).to have_http_status(:forbidden)
      end
    end
    
    context "as admin" do
      it "allows destroy" do
        request.headers.merge!(auth_headers(admin))
        delete :destroy, params: { id: resource.id }
        expect(response).to have_http_status(:no_content)
      end
    end
  end
end