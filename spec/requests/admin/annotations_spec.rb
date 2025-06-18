require 'rails_helper'

RSpec.describe "Admin::Annotations", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:regular_user) { create(:user) }
  
  before do
    # Set a valid host for tests
    host! 'test.example.com'
    
    # Disable maintenance mode for tests
    allow(Flipper).to receive(:enabled?).with(ApplicationConstants::Features::MAINTENANCE_MODE).and_return(false)
  end
  
  # Helper method to log in admin user
  def login_admin
    setup_admin_auth(admin_user)
  end
  
  describe "GET /admin/annotations" do
    let!(:annotations) { create_list(:annotation, 3, user: admin_user) }
    
    before { login_admin }
    
    it "returns successful response" do
      get admin_annotations_path
      expect(response).to have_http_status(:success)
    end
    
    it "displays annotations" do
      get admin_annotations_path
      annotations.each do |annotation|
        expect(response.body).to include(annotation.title)
      end
    end
    
    context "with filters" do
      let!(:critical_annotation) { create(:annotation, priority_level: 'critical', event_type: 'emergency') }
      let!(:low_annotation) { create(:annotation, priority_level: 'low', event_type: 'other') }
      
      it "filters by priority level" do
        get admin_annotations_path(priority_level: 'critical')
        expect(response.body).to include(critical_annotation.title)
        expect(response.body).not_to include(low_annotation.title)
      end
      
      it "filters by event type" do
        get admin_annotations_path(event_type: 'emergency')
        expect(response.body).to include(critical_annotation.title)
        expect(response.body).not_to include(low_annotation.title)
      end
      
      it "filters by search term" do
        searchable = create(:annotation, title: 'Earthquake in California')
        get admin_annotations_path(search: 'earthquake')
        expect(response.body).to include(searchable.title)
      end
    end
    
    context "with turbo stream request" do
      it "returns turbo stream response" do
        get admin_annotations_path, headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
      end
    end
  end
  
  describe "GET /admin/annotations/:id" do
    let(:annotation) { create(:annotation, user: admin_user) }
    let!(:annotation_stream) { create(:annotation_stream, annotation: annotation) }
    
    before { login_admin }
    
    it "returns successful response" do
      get admin_annotation_path(annotation)
      expect(response).to have_http_status(:success)
    end
    
    it "displays annotation details" do
      get admin_annotation_path(annotation)
      expect(response.body).to include(annotation.title)
      expect(response.body).to include(annotation.event_type.humanize)
    end
    
    it "displays linked streams" do
      get admin_annotation_path(annotation)
      expect(response.body).to include(annotation_stream.stream.source)
    end
  end
  
  describe "GET /admin/annotations/new" do
    before { login_admin }
    
    it "returns successful response" do
      get new_admin_annotation_path
      expect(response).to have_http_status(:success)
    end
    
    it "displays form" do
      get new_admin_annotation_path
      expect(response.body).to include('form')
      expect(response.body).to include('Event Title')
    end
  end
  
  describe "POST /admin/annotations" do
    before { login_admin }
    
    let(:valid_params) do
      {
        annotation: {
          title: 'Major Earthquake',
          event_type: 'emergency',
          priority_level: 'critical',
          event_timestamp: Time.current,
          description: 'A major earthquake has struck the region'
        }
      }
    end
    
    context "with valid params" do
      it "creates annotation" do
        expect {
          post admin_annotations_path, params: valid_params
        }.to change(Annotation, :count).by(1)
      end
      
      it "redirects to index" do
        post admin_annotations_path, params: valid_params
        expect(response).to redirect_to(admin_annotations_path)
      end
      
      it "sets current user as creator" do
        post admin_annotations_path, params: valid_params
        expect(Annotation.last.user).to eq(admin_user)
      end
      
      context "with turbo stream request" do
        it "returns turbo stream response" do
          post admin_annotations_path, params: valid_params, headers: { "Accept" => "text/vnd.turbo-stream.html" }
          expect(response.content_type).to include("text/vnd.turbo-stream.html")
        end
      end
    end
    
    context "with invalid params" do
      let(:invalid_params) do
        { annotation: { title: '', event_type: '' } }
      end
      
      it "does not create annotation" do
        expect {
          post admin_annotations_path, params: invalid_params
        }.not_to change(Annotation, :count)
      end
      
      it "returns unprocessable entity" do
        post admin_annotations_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
  
  describe "GET /admin/annotations/:id/edit" do
    let(:annotation) { create(:annotation, user: admin_user) }
    
    before { login_admin }
    
    it "returns successful response" do
      get edit_admin_annotation_path(annotation)
      expect(response).to have_http_status(:success)
    end
    
    it "displays form with annotation data" do
      get edit_admin_annotation_path(annotation)
      expect(response.body).to include(annotation.title)
    end
  end
  
  describe "PATCH /admin/annotations/:id" do
    let(:annotation) { create(:annotation, user: admin_user) }
    
    before { login_admin }
    
    let(:update_params) do
      {
        annotation: {
          title: 'Updated Title',
          priority_level: 'high'
        }
      }
    end
    
    context "with valid params" do
      it "updates annotation" do
        patch admin_annotation_path(annotation), params: update_params
        annotation.reload
        expect(annotation.title).to eq('Updated Title')
        expect(annotation.priority_level).to eq('high')
      end
      
      it "redirects to show page" do
        patch admin_annotation_path(annotation), params: update_params
        expect(response).to redirect_to(admin_annotation_path(annotation))
      end
    end
    
    context "with invalid params" do
      let(:invalid_params) do
        { annotation: { title: '' } }
      end
      
      it "does not update annotation" do
        original_title = annotation.title
        patch admin_annotation_path(annotation), params: invalid_params
        annotation.reload
        expect(annotation.title).to eq(original_title)
      end
    end
  end
  
  describe "DELETE /admin/annotations/:id" do
    let!(:annotation) { create(:annotation, user: admin_user) }
    
    before { login_admin }
    
    it "deletes annotation" do
      expect {
        delete admin_annotation_path(annotation)
      }.to change(Annotation, :count).by(-1)
    end
    
    it "redirects to index" do
      delete admin_annotation_path(annotation)
      expect(response).to redirect_to(admin_annotations_path)
    end
    
    context "with turbo stream request" do
      it "returns turbo stream response" do
        delete admin_annotation_path(annotation), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
      end
    end
  end
  
  describe "PATCH /admin/annotations/:id/resolve" do
    let(:annotation) { create(:annotation, user: admin_user, review_status: 'pending') }
    
    before { login_admin }
    
    it "marks annotation as resolved" do
      patch resolve_admin_annotation_path(annotation), params: { resolution_notes: 'All clear' }
      annotation.reload
      expect(annotation.review_status).to eq('resolved')
      expect(annotation.resolved_at).to be_present
      expect(annotation.resolved_by_user).to eq(admin_user)
      expect(annotation.resolution_notes).to eq('All clear')
    end
    
    it "redirects to show page" do
      patch resolve_admin_annotation_path(annotation)
      expect(response).to redirect_to(admin_annotation_path(annotation))
    end
  end
  
  describe "PATCH /admin/annotations/:id/dismiss" do
    let(:annotation) { create(:annotation, user: admin_user, review_status: 'pending') }
    
    before { login_admin }
    
    it "marks annotation as dismissed" do
      patch dismiss_admin_annotation_path(annotation), params: { dismissal_notes: 'False alarm' }
      annotation.reload
      expect(annotation.review_status).to eq('dismissed')
      expect(annotation.resolved_at).to be_present
      expect(annotation.resolved_by_user).to eq(admin_user)
    end
    
    it "redirects to show page" do
      patch dismiss_admin_annotation_path(annotation)
      expect(response).to redirect_to(admin_annotation_path(annotation))
    end
  end
  
  describe "POST /admin/annotations/:id/add_stream" do
    let(:annotation) { create(:annotation, user: admin_user) }
    let(:stream) { create(:stream) }
    
    before { login_admin }
    
    let(:params) do
      {
        stream_id: stream.id,
        timestamp_seconds: 120,
        relevance_score: 4,
        stream_notes: 'Event visible at 2:00'
      }
    end
    
    it "adds stream to annotation" do
      expect {
        post add_stream_admin_annotation_path(annotation), params: params
      }.to change(annotation.annotation_streams, :count).by(1)
    end
    
    it "creates annotation_stream with correct attributes" do
      post add_stream_admin_annotation_path(annotation), params: params
      annotation_stream = annotation.annotation_streams.last
      
      expect(annotation_stream.stream).to eq(stream)
      expect(annotation_stream.stream_timestamp_seconds).to eq(120)
      expect(annotation_stream.relevance_score).to eq(4)
      expect(annotation_stream.stream_notes).to eq('Event visible at 2:00')
      expect(annotation_stream.added_by_user).to eq(admin_user)
    end
    
    it "redirects to show page" do
      post add_stream_admin_annotation_path(annotation), params: params
      expect(response).to redirect_to(admin_annotation_path(annotation))
    end
  end
  
  describe "authorization" do
    it "redirects non-admin users" do
      # Don't set up admin auth for this test
      get admin_annotations_path
      expect(response).to redirect_to(admin_login_path)
    end
  end
end