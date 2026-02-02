module AdminHelpers
  # Setup admin authentication for request specs
  def setup_admin_auth(user = nil)
    admin_user = user || create(:user, :admin)
    sign_in_admin(admin_user)
  end

  # Sign in an admin user for request specs
  def sign_in_admin(user = nil, password: "Password123!")
    admin_user = user || create(:user, :admin, password: password)
    post admin_login_path, params: {
      email: admin_user.email,
      password: password,
    }
    admin_user
  end

  # Helper to assert successful admin page response
  def expect_admin_page_success
    expect(response).to have_http_status(:success)
    expect(response.content_type).to include("text/html")
  end

  # Helper to assert admin redirect
  def expect_admin_redirect_to(path)
    expect(response).to have_http_status(:redirect)
    expect(response).to redirect_to(path)
  end

  # Helper to check if content appears in admin view
  def expect_admin_page_to_include(*contents)
    contents.each do |content|
      expect(response.body).to include(content.to_s)
    end
  end

  # Helper to check if content does not appear in admin view
  def expect_admin_page_not_to_include(*contents)
    contents.each do |content|
      expect(response.body).not_to include(content.to_s)
    end
  end
end

RSpec.configure do |config|
  config.include AdminHelpers, type: :request
end
