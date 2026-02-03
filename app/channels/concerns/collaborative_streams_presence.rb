# Presence helpers for collaborative stream editing.
module CollaborativeStreamsPresence
  extend ActiveSupport::Concern

  PRESENCE_TTL = 12.minutes
  INACTIVITY_THRESHOLD = 10.minutes

  def track_user_presence
    touch_user_presence(action: true)
  end

  def touch_user_presence(action: false)
    store_user_presence(action: action)
    broadcast_active_users_list
  end

  def store_user_presence(action: false)
    payload = current_user_payload(action: action)
    redis.setex(user_presence_key(current_user.id), PRESENCE_TTL, payload.to_json)
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
    last_action_at = parse_time(user_data["last_action_at"]) || Time.current
    {
      user_id: user_data["id"],
      user_name: user_data["name"],
      user_color: user_data["color"],
      inactive: last_action_at < Time.current - INACTIVITY_THRESHOLD,
    }
  rescue JSON::ParserError => e
    Rails.logger.error("Failed to parse user data: #{e.message}")
    redis.srem(active_users_key, user_id)
    nil
  end

  def broadcast_active_users_list
    active_users = fetch_active_users
    ActionCable.server.broadcast(channel_name, {
                                   action: "active_users_list",
                                   users: active_users,
                                 })
  end

  def remove_user_presence
    redis.srem(active_users_key, current_user.id)
    redis.del(user_presence_key(current_user.id))
    broadcast_active_users_list
  end

  def active_users_key
    "#{channel_name}:users"
  end

  def user_presence_key(user_id)
    "#{channel_name}:user:#{user_id}"
  end

  def current_user_payload(action: false)
    now = Time.current
    last_action_at = action ? now : existing_last_action_at || now
    {
      id: current_user.id,
      name: current_user.display_name,
      color: user_color,
      last_seen_at: now.iso8601,
      last_action_at: last_action_at.iso8601,
    }
  end

  def user_color
    user_color_for(current_user)
  end

  def user_color_for(user)
    UserColorPalette.color_for(user.id)
  end

  def existing_last_action_at
    payload = redis.get(user_presence_key(current_user.id))
    return nil if payload.blank?

    data = JSON.parse(payload)
    parse_time(data["last_action_at"])
  rescue JSON::ParserError
    nil
  end

  def parse_time(value)
    return nil if value.blank?

    Time.zone.parse(value.to_s)
  rescue ArgumentError
    nil
  end
end
