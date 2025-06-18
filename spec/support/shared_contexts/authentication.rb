# Shared contexts for authentication setup

RSpec.shared_context "with admin authentication" do
  let(:admin_user) { create(:user, :admin) }
  
  before do
    setup_admin_auth(admin_user)
  end
end

RSpec.shared_context "with editor authentication" do
  let(:editor_user) { create(:user, :editor) }
  let(:auth_headers) { auth_headers(editor_user) }
  
  before do
    request.headers.merge!(auth_headers) if defined?(request)
  end
end

RSpec.shared_context "with default user authentication" do
  let(:default_user) { create(:user, :default) }
  let(:auth_headers) { auth_headers(default_user) }
  
  before do
    request.headers.merge!(auth_headers) if defined?(request)
  end
end

RSpec.shared_context "with different user roles" do
  let(:admin_user) { create(:user, :admin) }
  let(:editor_user) { create(:user, :editor) }
  let(:default_user) { create(:user, :default) }
  let(:another_editor) { create(:user, :editor) }
  
  let(:admin_headers) { auth_headers(admin_user) }
  let(:editor_headers) { auth_headers(editor_user) }
  let(:default_headers) { auth_headers(default_user) }
  let(:another_editor_headers) { auth_headers(another_editor) }
end

RSpec.shared_context "with JWT variations" do
  let(:user) { create(:user) }
  let(:valid_headers) { auth_headers(user) }
  let(:expired_headers) { expired_auth_headers(user) }
  let(:invalid_headers) { invalid_auth_headers }
  let(:malformed_headers) { malformed_auth_headers }
  let(:no_headers) { no_auth_headers }
end

RSpec.shared_context "with sample resources" do
  let(:user) { create(:user, :editor) }
  let(:another_user) { create(:user, :editor) }
  let(:admin) { create(:user, :admin) }
  
  let!(:user_stream) { create(:stream, :live, user: user) }
  let!(:another_user_stream) { create(:stream, user: another_user) }
  let!(:pinned_stream) { create(:stream, user: user, is_pinned: true) }
  let!(:offline_stream) { create(:stream, user: user, status: 'Offline') }
  
  let!(:user_streamer) { create(:streamer, user: user) }
  let!(:another_user_streamer) { create(:streamer, user: another_user) }
end