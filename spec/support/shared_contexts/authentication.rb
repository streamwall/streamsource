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

  def admin_headers
    auth_headers(admin_user)
  end

  def editor_headers
    auth_headers(editor_user)
  end

  def default_headers
    auth_headers(default_user)
  end

  def another_editor_headers
    auth_headers(another_editor)
  end
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

  let(:streams) do
    {
      user_stream: create(:stream, :live, user: user),
      another_user_stream: create(:stream, user: another_user),
      pinned_stream: create(:stream, user: user, is_pinned: true),
      offline_stream: create(:stream, user: user, status: "Offline"),
    }
  end

  let(:streamers) do
    {
      user_streamer: create(:streamer, user: user),
      another_user_streamer: create(:streamer, user: another_user),
    }
  end

  def user_stream
    streams[:user_stream]
  end

  def another_user_stream
    streams[:another_user_stream]
  end

  def pinned_stream
    streams[:pinned_stream]
  end

  def offline_stream
    streams[:offline_stream]
  end

  def user_streamer
    streamers[:user_streamer]
  end

  def another_user_streamer
    streamers[:another_user_streamer]
  end
end
