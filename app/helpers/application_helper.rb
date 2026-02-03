# View helpers shared across the app.
module ApplicationHelper
  def user_color(user)
    UserColorPalette.color_for(user.id)
  end

  def time_ago_in_words_with_nil(time)
    return "Never" if time.nil?

    "#{time_ago_in_words(time)} ago"
  end

  def stream_status_color(status)
    case status
    when "live"
      "bg-green-100 text-green-800"
    when "error"
      "bg-red-100 text-red-800"
    when "checking"
      "bg-yellow-100 text-yellow-800"
    when "archived"
      "bg-purple-100 text-purple-800"
    else
      "bg-gray-100 text-gray-800"
    end
  end
end
