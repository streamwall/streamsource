# Shared examples for CRUD operations

RSpec.shared_examples "successful index action" do |options = {}|
  let(:resource_name) { options[:resource] || described_class.controller_name.singularize }
  let(:collection_name) { options[:collection] || resource_name.pluralize }

  it "returns successful response" do
    get :index
    expect(response).to have_http_status(:success)
  end

  if options[:assigns] != false
    it "assigns the collection" do
      resources = create_list(resource_name.to_sym, 3)
      get :index
      expect(assigns(collection_name.to_sym)).to match_array(resources)
    end
  end
end

RSpec.shared_examples "successful show action" do |options = {}|
  let(:resource_name) { options[:resource] || described_class.controller_name.singularize }
  let(:resource) { create(resource_name.to_sym) }

  it "returns successful response" do
    get :show, params: { id: resource.id }
    expect(response).to have_http_status(:success)
  end

  if options[:assigns] != false
    it "assigns the resource" do
      get :show, params: { id: resource.id }
      expect(assigns(resource_name.to_sym)).to eq(resource)
    end
  end
end

RSpec.shared_examples "successful create action" do |options = {}|
  let(:resource_name) { options[:resource] || described_class.controller_name.singularize }
  let(:resource_class) { resource_name.camelize.constantize }
  let(:valid_params) { options[:valid_params] || attributes_for(resource_name.to_sym) }
  let(:invalid_params) { options[:invalid_params] || { source: "", link: "" } }

  context "with valid params" do
    it "creates a new resource" do
      expect do
        post :create, params: { resource_name => valid_params }
      end.to change(resource_class, :count).by(1)
    end

    it "returns created status" do
      post :create, params: { resource_name => valid_params }
      expect(response).to have_http_status(:created)
    end

    if options[:format] == :json
      it "returns the created resource" do
        post :create, params: { resource_name => valid_params }
        json = JSON.parse(response.body)
        expect(json["id"]).to be_present
      end
    end
  end

  context "with invalid params" do
    it "does not create a resource" do
      expect do
        post :create, params: { resource_name => invalid_params }
      end.not_to change(resource_class, :count)
    end

    it "returns unprocessable entity" do
      post :create, params: { resource_name => invalid_params }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end

RSpec.shared_examples "successful update action" do |options = {}|
  let(:resource_name) { options[:resource] || described_class.controller_name.singularize }
  let(:resource) { create(resource_name.to_sym) }
  let(:update_params) { options[:update_params] || { source: "Updated Source" } }
  let(:invalid_params) { options[:invalid_params] || { source: "" } }

  context "with valid params" do
    it "updates the resource" do
      patch :update, params: { id: resource.id, resource_name => update_params }
      resource.reload
      update_params.each do |key, value|
        expect(resource.send(key)).to eq(value)
      end
    end

    it "returns success" do
      patch :update, params: { id: resource.id, resource_name => update_params }
      expect(response).to have_http_status(:success)
    end
  end

  context "with invalid params" do
    it "does not update the resource" do
      original_attributes = resource.attributes
      patch :update, params: { id: resource.id, resource_name => invalid_params }
      resource.reload
      expect(resource.attributes).to eq(original_attributes)
    end

    it "returns unprocessable entity" do
      patch :update, params: { id: resource.id, resource_name => invalid_params }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end

RSpec.shared_examples "successful destroy action" do |options = {}|
  let(:resource_name) { options[:resource] || described_class.controller_name.singularize }
  let(:resource_class) { resource_name.camelize.constantize }
  let!(:resource) { create(resource_name.to_sym) }

  it "destroys the resource" do
    expect do
      delete :destroy, params: { id: resource.id }
    end.to change(resource_class, :count).by(-1)
  end

  if options[:format] == :json
    it "returns no content" do
      delete :destroy, params: { id: resource.id }
      expect(response).to have_http_status(:no_content)
    end
  end

  if options[:redirect_to]
    it "redirects appropriately" do
      delete :destroy, params: { id: resource.id }
      expect(response).to redirect_to(options[:redirect_to])
    end
  end
end

RSpec.shared_examples "admin crud actions" do |resource_name, options = {}|
  let(:admin_user) { create(:user, :admin) }
  let(:resource) { create(resource_name) }
  let(:resources) { create_list(resource_name, 3) }

  before { setup_admin_auth(admin_user) }

  describe "GET index" do
    before { resources }

    it "returns successful response" do
      get :index
      expect_admin_page_success
    end

    it "displays all resources" do
      get :index
      resources.each do |resource|
        display_value = options[:display_attribute] ? resource.public_send(options[:display_attribute]) : resource.id
        expect_admin_page_to_include(display_value)
      end
    end
  end

  describe "GET show" do
    it "returns successful response" do
      get :show, params: { id: resource.id }
      expect_admin_page_success
    end

    it "displays resource details" do
      get :show, params: { id: resource.id }
      options[:show_attributes]&.each do |attr|
        expect_admin_page_to_include(resource.send(attr))
      end
    end
  end

  describe "GET new" do
    it "returns successful response" do
      get :new
      expect_admin_page_success
    end
  end

  describe "POST create" do
    let(:valid_params) { options[:valid_params] || attributes_for(resource_name) }
    let(:invalid_params) { options[:invalid_params] || {} }

    context "with valid params" do
      it "creates resource" do
        expect do
          post :create, params: { resource_name => valid_params }
        end.to change(resource_name.to_s.camelize.constantize, :count).by(1)
      end

      it "redirects to appropriate page" do
        post :create, params: { resource_name => valid_params }
        expect_admin_redirect_to(options[:create_redirect] || send("admin_#{resource_name.to_s.pluralize}_path"))
      end
    end

    context "with invalid params" do
      it "does not create resource" do
        expect do
          post :create, params: { resource_name => invalid_params }
        end.not_to change(resource_name.to_s.camelize.constantize, :count)
      end

      it "returns unprocessable entity" do
        post :create, params: { resource_name => invalid_params }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE destroy" do
    it "deletes resource" do
      resource # create it first
      expect do
        delete :destroy, params: { id: resource.id }
      end.to change(resource_name.to_s.camelize.constantize, :count).by(-1)
    end

    it "redirects to index" do
      delete :destroy, params: { id: resource.id }
      expect_admin_redirect_to(options[:destroy_redirect] || send("admin_#{resource_name.to_s.pluralize}_path"))
    end
  end
end
