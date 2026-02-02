require "rails_helper"

RSpec.describe StreamPolicy do
  let(:user) { create(:user) }
  let(:editor) { create(:user, :editor) }
  let(:admin) { create(:user, :admin) }
  let(:stream) { create(:stream, user: editor) }
  let(:other_editor) { create(:user, :editor) }

  describe "#create?" do
    it "allows editors to create" do
      policy = described_class.new(editor, Stream.new)
      expect(policy.create?).to be true
    end

    it "allows admins to create" do
      policy = described_class.new(admin, Stream.new)
      expect(policy.create?).to be true
    end

    it "denies default users" do
      policy = described_class.new(user, Stream.new)
      expect(policy.create?).to be false
    end

    it "denies nil user" do
      policy = described_class.new(nil, Stream.new)
      expect(policy.create?).to be false
    end
  end

  describe "#update?" do
    context "when stream owner" do
      it "allows owner to update their stream" do
        policy = described_class.new(editor, stream)
        expect(policy.update?).to be true
      end
    end

    context "when non-owner editor" do
      it "denies non-owner editor" do
        policy = described_class.new(other_editor, stream)
        expect(policy.update?).to be false
      end
    end

    context "when admin" do
      it "allows admin to update any stream" do
        policy = described_class.new(admin, stream)
        expect(policy.update?).to be true
      end
    end

    context "when default user" do
      it "denies default user even if owner" do
        user_stream = create(:stream, user: user)
        policy = described_class.new(user, user_stream)
        expect(policy.update?).to be false
      end
    end
  end

  describe "#destroy?" do
    it "has same permissions as update" do
      # Test that destroy? delegates to update?
      policy = described_class.new(editor, stream)
      expect(policy.destroy?).to eq(policy.update?)

      policy = described_class.new(other_editor, stream)
      expect(policy.destroy?).to eq(policy.update?)

      policy = described_class.new(admin, stream)
      expect(policy.destroy?).to eq(policy.update?)
    end
  end

  describe "Scope" do
    let(:scoped_streams) do
      [
        create(:stream, user: user),
        create(:stream, user: editor),
        create(:stream, user: admin),
        create(:stream, user: other_editor),
      ]
    end

    before { scoped_streams }

    describe "#resolve" do
      it "returns all streams for any authenticated user" do
        scope = described_class::Scope.new(user, Stream.all)
        expect(scope.resolve).to match_array(scoped_streams)
      end

      it "returns all streams for editor" do
        scope = described_class::Scope.new(editor, Stream.all)
        expect(scope.resolve.count).to eq(4)
      end

      it "returns all streams for admin" do
        scope = described_class::Scope.new(admin, Stream.all)
        expect(scope.resolve.count).to eq(4)
      end

      it "returns no streams for nil user" do
        scope = described_class::Scope.new(nil, Stream.all)
        expect(scope.resolve).to be_empty
      end

      it "respects existing scopes" do
        scope = described_class::Scope.new(user, Stream.active)
        # Assuming all created streams are active by default
        expect(scope.resolve.count).to eq(4)
      end
    end
  end

  describe "edge cases" do
    it "handles stream without user" do
      stream_without_user = build(:stream)
      stream_without_user.user = nil

      policy = described_class.new(admin, stream_without_user)
      expect { policy.update? }.not_to raise_error
    end

    it "handles user checking their own nil stream" do
      policy = described_class.new(editor, nil)
      expect { policy.create? }.not_to raise_error
      expect(policy.create?).to be true
    end
  end
end
