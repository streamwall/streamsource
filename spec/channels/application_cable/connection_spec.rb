require "rails_helper"

RSpec.describe ApplicationCable::Connection, type: :channel do
  let(:user) { create(:user) }
  let(:token) { JsonWebToken.encode(user_id: user.id) }

  describe "#connect" do
    context "with valid JWT token in cookies" do
      it "successfully connects and identifies user" do
        cookies["jwt_token"] = token

        connect "/cable"

        expect(connection.current_user).to eq(user)
      end
    end

    context "with valid JWT token in params" do
      it "successfully connects and identifies user" do
        connect "/cable", params: { token: token }

        expect(connection.current_user).to eq(user)
      end
    end

    context "with invalid JWT token" do
      it "rejects connection" do
        cookies["jwt_token"] = "invalid_token"

        expect { connect "/cable" }.to have_rejected_connection
      end
    end

    context "without JWT token" do
      it "rejects connection" do
        expect { connect "/cable" }.to have_rejected_connection
      end
    end

    context "with expired JWT token" do
      it "rejects connection" do
        expired_token = JsonWebToken.encode({ user_id: user.id }, 1.day.ago)
        cookies["jwt_token"] = expired_token

        expect { connect "/cable" }.to have_rejected_connection
      end
    end

    context "with deleted user" do
      it "rejects connection" do
        cookies["jwt_token"] = token
        user.destroy

        expect { connect "/cable" }.to have_rejected_connection
      end
    end
  end

  describe "#disconnect" do
    it "can disconnect properly" do
      cookies["jwt_token"] = token
      connect "/cable"

      expect { disconnect }.not_to raise_error
    end
  end
end
