require "rails_helper"

RSpec.describe User, type: :model do
  describe "password validation" do
    context "on create" do
      it "validates password complexity" do
        user = build(:user, password: "simple")
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include("must include lowercase, uppercase, and number")
      end

      it "accepts valid password" do
        user = build(:user, password: "Valid123")
        expect(user).to be_valid
      end
    end

    context "on update" do
      let(:user) { create(:user) }

      it "validates password complexity when password is changed" do
        user.password = "simple123"
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include(ApplicationConstants::Password::COMPLEXITY_MESSAGE)
      end
    end
  end

  describe "email normalization" do
    it "downcases email before validation" do
      user = build(:user, email: "USER@EXAMPLE.COM")
      user.valid?
      expect(user.email).to eq("user@example.com")
    end

    it "strips whitespace from email" do
      user = build(:user, email: "  user@example.com  ")
      user.valid?
      expect(user.email).to eq("user@example.com")
    end
  end

  describe "authorization methods" do
    describe "#can_modify_streams?" do
      it "returns true for editor" do
        user = build(:user, :editor)
        expect(user.can_modify_streams?).to be true
      end

      it "returns true for admin" do
        user = build(:user, :admin)
        expect(user.can_modify_streams?).to be true
      end

      it "returns false for default user" do
        user = build(:user)
        expect(user.can_modify_streams?).to be false
      end
    end

    describe "#premium?" do
      it "returns true for admin" do
        user = build(:user, :admin)
        expect(user.premium?).to be true
      end

      it "returns false for non-admin" do
        user = build(:user)
        expect(user.premium?).to be false
      end
    end
  end

  describe "#display_name" do
    it "returns email before @ symbol" do
      user = build(:user, email: "john.doe@example.com")
      expect(user.display_name).to eq("john.doe")
    end
  end

  describe "#flipper_id" do
    it "returns formatted flipper id" do
      user = create(:user)
      expect(user.flipper_id).to eq("User:#{user.id}")
    end
  end
end
