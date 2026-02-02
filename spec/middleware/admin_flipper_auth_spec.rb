require "rails_helper"

RSpec.describe AdminFlipperAuth do
  let(:app) do
    Class.new do
      def call(_env)
        [200, {}, ["OK"]]
      end
    end.new
  end
  let(:middleware) { described_class.new(app) }
  let(:env) { Rack::MockRequest.env_for("/admin/flipper") }

  describe "#call" do
    context "when user is admin" do
      let(:admin_user) { create(:user, :admin) }

      before do
        allow(middleware).to receive(:current_user).and_return(admin_user)
        allow(app).to receive(:call).and_return([200, {}, ["OK"]])
      end

      it "allows access" do
        middleware.call(env)
        expect(app).to have_received(:call).with(env)
      end

      it "passes through to the app" do
        status, _, body = middleware.call(env)

        expect(status).to eq(200)
        expect(body).to eq(["OK"])
      end
    end

    context "when user is not admin" do
      let(:regular_user) { create(:user) }

      before do
        allow(middleware).to receive(:current_user).and_return(regular_user)
        allow(app).to receive(:call)
      end

      it "returns 403 forbidden" do
        status, _, body = middleware.call(env)

        expect(status).to eq(403)
        expect(body).to eq(["Forbidden"])
      end

      it "does not call the app" do
        middleware.call(env)
        expect(app).not_to have_received(:call)
      end

      it "sets content type header" do
        _, headers, = middleware.call(env)

        expect(headers["Content-Type"]).to eq("text/plain")
      end
    end

    context "when user is nil" do
      before do
        allow(middleware).to receive(:current_user).and_return(nil)
      end

      it "returns 403 forbidden" do
        status, _, body = middleware.call(env)

        expect(status).to eq(403)
        expect(body).to eq(["Forbidden"])
      end
    end

    context "when current_user raises an error" do
      before do
        allow(middleware).to receive(:current_user).and_raise(StandardError)
      end

      it "returns 403 forbidden" do
        status, _, body = middleware.call(env)

        expect(status).to eq(403)
        expect(body).to eq(["Forbidden"])
      end

      it "does not propagate the error" do
        expect { middleware.call(env) }.not_to raise_error
      end
    end
  end

  describe "#current_user" do
    let(:user) { create(:user) }
    let(:session) { { user_id: user.id } }

    context "with valid session" do
      before do
        env["rack.session"] = session
      end

      it "returns the user from session" do
        expect(middleware.send(:current_user, env)).to eq(user)
      end

      it "memoizes the user lookup" do
        allow(User).to receive(:find_by).and_return(user)

        2.times { middleware.send(:current_user, env) }

        expect(User).to have_received(:find_by).once
      end
    end

    context "with invalid user_id in session" do
      before do
        env["rack.session"] = { user_id: 999_999 }
      end

      it "returns nil" do
        expect(middleware.send(:current_user, env)).to be_nil
      end
    end

    context "without session" do
      it "returns nil" do
        expect(middleware.send(:current_user, env)).to be_nil
      end
    end

    context "with nil session" do
      before do
        env["rack.session"] = nil
      end

      it "returns nil" do
        expect(middleware.send(:current_user, env)).to be_nil
      end
    end
  end

  describe "integration" do
    let(:admin_user) { create(:user, :admin) }
    let(:regular_user) { create(:user) }
    let(:env_with_session) { Rack::MockRequest.env_for("/admin/flipper") }

    it "integrates with rack session" do
      env_with_session["rack.session"] = { user_id: admin_user.id }
      allow(app).to receive(:call).and_return([200, {}, ["Success"]])

      status, = middleware.call(env_with_session)

      expect(status).to eq(200)
    end

    it "denies access for non-admin in session" do
      env_with_session["rack.session"] = { user_id: regular_user.id }

      status, = middleware.call(env_with_session)

      expect(status).to eq(403)
    end
  end
end
