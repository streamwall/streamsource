module UserColorPalette
  COLORS = ["#0072B2", "#E69F00", "#009E73", "#D55E00", "#CC79A7", "#56B4E9", "#F0E442", "#000000"].freeze

  def self.color_for(user_id)
    COLORS[user_id.to_i % COLORS.length]
  end
end
