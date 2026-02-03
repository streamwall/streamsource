# Provides deterministic colors for users based on their IDs.
module UserColorPalette
  COLORS = ["#FF6B6B", "#4ECDC4", "#45B7D1", "#FFA07A", "#98D8C8", "#F7DC6F", "#BB8FCE", "#85C1E2"].freeze

  def self.color_for(user_id)
    COLORS[user_id.to_i % COLORS.length]
  end
end
