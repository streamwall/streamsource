require 'rails_helper'

RSpec.describe "Admin::Notes", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:stream) { create(:stream) }
  let(:streamer) { create(:streamer) }
  
  before do
    allow_any_instance_of(Admin::BaseController).to receive(:current_admin_user).and_return(admin_user)
    allow_any_instance_of(Admin::BaseController).to receive(:authenticate_admin!).and_return(true)
  end
  
  describe "POST /admin/streams/:stream_id/notes" do
    let(:valid_params) do
      {
        note: {
          content: 'This is an important note about the stream'
        }
      }
    end
    
    context "with valid params" do
      it "creates note" do
        expect {
          post admin_stream_notes_path(stream), params: valid_params
        }.to change(Note, :count).by(1)
      end
      
      it "associates note with stream" do
        post admin_stream_notes_path(stream), params: valid_params
        note = Note.last
        expect(note.notable).to eq(stream)
        expect(note.user).to eq(admin_user)
      end
      
      it "redirects to stream" do
        post admin_stream_notes_path(stream), params: valid_params
        expect(response).to redirect_to(admin_stream_path(stream))
      end
    end
    
    context "with invalid params" do
      let(:invalid_params) do
        { note: { content: '' } }
      end
      
      it "does not create note" do
        expect {
          post admin_stream_notes_path(stream), params: invalid_params
        }.not_to change(Note, :count)
      end
    end
  end
  
  describe "POST /admin/streamers/:streamer_id/notes" do
    let(:valid_params) do
      {
        note: {
          content: 'This streamer is known for gaming content'
        }
      }
    end
    
    it "creates note for streamer" do
      expect {
        post admin_streamer_notes_path(streamer), params: valid_params
      }.to change(Note, :count).by(1)
    end
    
    it "associates note with streamer" do
      post admin_streamer_notes_path(streamer), params: valid_params
      note = Note.last
      expect(note.notable).to eq(streamer)
    end
  end
  
  describe "GET /admin/streams/:stream_id/notes/:id/edit" do
    let(:note) { create(:note, notable: stream, user: admin_user) }
    
    it "returns successful response" do
      get admin_stream_edit_note_path(stream, note)
      expect(response).to have_http_status(:success)
    end
  end
  
  describe "PATCH /admin/streams/:stream_id/notes/:id" do
    let(:note) { create(:note, notable: stream, user: admin_user) }
    let(:update_params) do
      {
        note: {
          content: 'Updated note content'
        }
      }
    end
    
    it "updates note" do
      patch admin_stream_note_path(stream, note), params: update_params
      note.reload
      expect(note.content).to eq('Updated note content')
    end
    
    it "redirects to stream" do
      patch admin_stream_note_path(stream, note), params: update_params
      expect(response).to redirect_to(admin_stream_path(stream))
    end
    
    context "when user does not own note" do
      let(:other_user) { create(:user, :admin) }
      let(:note) { create(:note, notable: stream, user: other_user) }
      
      it "still allows update (admin privilege)" do
        patch admin_stream_note_path(stream, note), params: update_params
        note.reload
        expect(note.content).to eq('Updated note content')
      end
    end
  end
  
  describe "DELETE /admin/streams/:stream_id/notes/:id" do
    let!(:note) { create(:note, notable: stream, user: admin_user) }
    
    it "deletes note" do
      expect {
        delete admin_stream_note_path(stream, note)
      }.to change(Note, :count).by(-1)
    end
    
    it "redirects to stream" do
      delete admin_stream_note_path(stream, note)
      expect(response).to redirect_to(admin_stream_path(stream))
    end
  end
  
  describe "with turbo stream requests" do
    let(:note) { create(:note, notable: stream, user: admin_user) }
    
    it "returns turbo stream response for create" do
      post admin_stream_notes_path(stream), 
           params: { note: { content: 'New note' } },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response.content_type).to include("text/vnd.turbo-stream.html")
    end
    
    it "returns turbo stream response for update" do
      patch admin_stream_note_path(stream, note),
            params: { note: { content: 'Updated' } },
            headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response.content_type).to include("text/vnd.turbo-stream.html")
    end
    
    it "returns turbo stream response for destroy" do
      delete admin_stream_note_path(stream, note),
             headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response.content_type).to include("text/vnd.turbo-stream.html")
    end
  end
end