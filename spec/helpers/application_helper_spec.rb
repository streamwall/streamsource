require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#user_color" do
    let(:user) { build_stubbed(:user, id: id) }

    context "with various user ids" do
      it "returns consistent color for same user" do
        user = build_stubbed(:user, id: 1)
        color1 = helper.user_color(user)
        color2 = helper.user_color(user)
        expect(color1).to eq(color2)
      end

      it "returns different colors for different users" do
        user1 = build_stubbed(:user, id: 1)
        user2 = build_stubbed(:user, id: 2)
        expect(helper.user_color(user1)).not_to eq(helper.user_color(user2))
      end

      it "cycles through all available colors" do
        colors = ["#FF6B6B", "#4ECDC4", "#45B7D1", "#FFA07A", "#98D8C8", "#F7DC6F", "#BB8FCE", "#85C1E2"]

        colors.each_with_index do |expected_color, index|
          user = build_stubbed(:user, id: index)
          expect(helper.user_color(user)).to eq(expected_color)
        end
      end

      it "wraps around when user id exceeds color array length" do
        user1 = build_stubbed(:user, id: 0)
        user2 = build_stubbed(:user, id: 8) # Should wrap to same color as id: 0
        expect(helper.user_color(user1)).to eq(helper.user_color(user2))
      end

      it "handles large user ids" do
        user = build_stubbed(:user, id: 1000)
        expect(helper.user_color(user)).to be_a(String)
        expect(helper.user_color(user)).to match(/^#[0-9A-F]{6}$/i)
      end
    end
  end

  describe "#time_ago_in_words_with_nil" do
    context "when time is nil" do
      it 'returns "Never"' do
        expect(helper.time_ago_in_words_with_nil(nil)).to eq("Never")
      end
    end

    context "when time is present" do
      it "returns time ago string for recent time" do
        time = 5.minutes.ago
        result = helper.time_ago_in_words_with_nil(time)
        expect(result).to include("minutes ago")
      end

      it "returns time ago string for time in hours" do
        time = 2.hours.ago
        result = helper.time_ago_in_words_with_nil(time)
        expect(result).to include("about 2 hours ago")
      end

      it "returns time ago string for time in days" do
        time = 3.days.ago
        result = helper.time_ago_in_words_with_nil(time)
        expect(result).to include("3 days ago")
      end

      it 'includes "ago" suffix' do
        time = 1.hour.ago
        result = helper.time_ago_in_words_with_nil(time)
        expect(result).to end_with("ago")
      end

      it "handles very recent times" do
        time = 1.second.ago
        result = helper.time_ago_in_words_with_nil(time)
        expect(result).to include("less than a minute ago")
      end

      it "handles future times" do
        time = 1.hour.from_now
        result = helper.time_ago_in_words_with_nil(time)
        # Rails time_ago_in_words handles future times as negative ago
        expect(result).to be_a(String)
        expect(result).to include("ago")
      end
    end
  end
end
