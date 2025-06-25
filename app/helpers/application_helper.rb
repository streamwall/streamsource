module ApplicationHelper
  def user_color(user)
    colors = ['#FF6B6B', '#4ECDC4', '#45B7D1', '#FFA07A', '#98D8C8', '#F7DC6F', '#BB8FCE', '#85C1E2']
    colors[user.id % colors.length]
  end
end