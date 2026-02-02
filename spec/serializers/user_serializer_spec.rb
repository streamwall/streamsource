require "rails_helper"

RSpec.describe UserSerializer do
  let(:user) { create(:user, :admin, email: "admin@test.com") }
  let(:serializer) { described_class.new(user) }
  let(:serialization) { ActiveModelSerializers::Adapter.create(serializer).as_json[:user] }

  describe "attributes" do
    it "includes id" do
      expect(serialization[:id]).to eq(user.id)
    end

    it "includes email" do
      expect(serialization[:email]).to eq("admin@test.com")
    end

    it "includes role" do
      expect(serialization[:role]).to eq("admin")
    end

    it "includes created_at" do
      expect(serialization[:created_at].iso8601(3)).to eq(user.created_at.iso8601(3))
    end

    it "includes updated_at" do
      expect(serialization[:updated_at].iso8601(3)).to eq(user.updated_at.iso8601(3))
    end

    it "does not include password_digest" do
      expect(serialization).not_to have_key(:password_digest)
    end

    it "does not include password" do
      expect(serialization).not_to have_key(:password)
    end
  end

  describe "with different roles" do
    it "serializes default user correctly" do
      default_user = create(:user)
      serialization = ActiveModelSerializers::Adapter.create(described_class.new(default_user)).as_json[:user]

      expect(serialization[:role]).to eq("default")
    end

    it "serializes editor correctly" do
      editor = create(:user, :editor)
      serialization = ActiveModelSerializers::Adapter.create(described_class.new(editor)).as_json[:user]

      expect(serialization[:role]).to eq("editor")
    end
  end

  describe "collection serialization" do
    let(:users) { create_list(:user, 3) }
    let(:serializer) { ActiveModel::Serializer::CollectionSerializer.new(users, serializer: described_class) }
    let(:serialization) { ActiveModelSerializers::Adapter.create(serializer).as_json[:users] }

    it "serializes multiple users" do
      expect(serialization).to be_an(Array)
      expect(serialization.length).to eq(3)
    end

    it "includes all attributes for each user" do
      expect(serialization).to all(
        include(:id, :email, :role, :created_at, :updated_at),
      )
    end
  end
end
