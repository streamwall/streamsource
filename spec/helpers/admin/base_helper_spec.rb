require "rails_helper"

RSpec.describe Admin::BaseHelper, type: :helper do
  describe "module inclusion" do
    it "includes ApplicationHelper" do
      expect(described_class.ancestors).to include(ApplicationHelper)
    end

    it "has access to ApplicationHelper methods" do
      # Test that methods from ApplicationHelper are available
      expect(helper).to respond_to(:user_color)
      expect(helper).to respond_to(:time_ago_in_words_with_nil)
    end

    it "delegates user_color to ApplicationHelper" do
      user = build_stubbed(:user, id: 1)
      expect(helper.user_color(user)).to eq("#4ECDC4")
    end

    it "delegates time_ago_in_words_with_nil to ApplicationHelper" do
      expect(helper.time_ago_in_words_with_nil(nil)).to eq("Never")

      time = 5.minutes.ago
      result = helper.time_ago_in_words_with_nil(time)
      expect(result).to include("minutes ago")
    end
  end

  describe "module structure" do
    it "is defined within Admin module" do
      expect(described_class.name).to eq("Admin::BaseHelper")
    end

    it "is a module" do
      expect(described_class).to be_a(Module)
    end
  end
end
