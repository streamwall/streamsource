# Presence helpers for collaborative stream editing.
module CollaborativeStreamsPresence
  extend ActiveSupport::Concern

  PRESENCE_TTL = 300

  def track_user_presence
    store_user_presence
    active_users = fetch_active_users
    log_active_users(active_users)
    transmit(action: "active_users_list", users: active_users)
    broadcast_user_joined
  end

  def store_user_presence
    redis.setex(user_presence_key(current_user.id), PRESENCE_TTL, current_user_payload.to_json)
    redis.sadd(active_users_key, current_user.id)
  end

  def fetch_active_users
    users = []

    redis.smembers(active_users_key).each do |user_id|
      user_json = redis.get(user_presence_key(user_id))
      if user_json.nil?
        redis.srem(active_users_key, user_id)
        next
      end

      user_data = parse_user_data(user_json, user_id)
      users << user_data if user_data
    end

    users.sort_by { |user| user[:user_id] }
  end

  def parse_user_data(user_json, user_id)
    user_data = JSON.parse(user_json)
    {
      user_id: user_data["id"],
      user_name: user_data["name"],
      user_color: user_data["color"],
    }
  rescue JSON::ParserError => e
    Rails.logger.error("Failed to parse user data: #{e.message}")
    redis.srem(active_users_key, user_id)
    nil
  end

  def log_active_users(active_users)
    names = active_users.pluck(:user_name).join(", ")
    Rails.logger.info("Active users for #{current_user.email}: #{names}")
  end

  def broadcast_user_joined
    ActionCable.server.broadcast(channel_name, {
                                   action: "user_joined",
                                   user_id: current_user.id,
                                   user_name: current_user.display_name,
                                   user_color: user_color,
                                 })
  end

  def remove_user_presence
    redis.srem(active_users_key, current_user.id)
    redis.del(user_presence_key(current_user.id))
    broadcast_user_left
  end

  def broadcast_user_left
    ActionCable.server.broadcast(channel_name, {
                                   action: "user_left",
                                   user_id: current_user.id,
                                 })
  end

  def active_users_key
    "#{channel_name}:users"
  end

  def user_presence_key(user_id)
    "#{channel_name}:user:#{user_id}"
  end

  def current_user_payload
    {
      id: current_user.id,
      name: current_user.display_name,
      color: user_color,
    }
  end

  def user_color
    user_color_for(current_user)
  end

  def user_color_for(user)
    colors = ["#FF6B6B", "#4ECDC4", "#45B7D1", "#FFA07A", "#98D8C8", "#F7DC6F", "#BB8FCE", "#85C1E2"]
    colors[user.id % colors.length]
  end
end
