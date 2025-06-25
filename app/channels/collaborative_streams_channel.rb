class CollaborativeStreamsChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'collaborative_streams'

    # Track user presence
    track_user_presence
  end

  def unsubscribed
    # Remove user presence and unlock any cells
    remove_user_presence
    unlock_all_user_cells
  end

  def lock_cell(data)
    cell_id = data['cell_id']

    # Check if cell is already locked by another user
    if cell_locked_by_other?(cell_id)
      reject
      return
    end

    # Lock the cell for this user
    lock_cell_for_user(cell_id)

    # Broadcast lock status to all users
    ActionCable.server.broadcast('collaborative_streams', {
                                   action: 'cell_locked',
                                   cell_id: cell_id,
                                   user_id: current_user.id,
                                   user_name: current_user.display_name,
                                   user_color: user_color
                                 })
  end

  def unlock_cell(data)
    cell_id = data['cell_id']

    # Only unlock if this user has the lock
    return unless cell_locked_by_user?(cell_id)

    unlock_cell_for_user(cell_id)

    # Broadcast unlock status to all users
    ActionCable.server.broadcast('collaborative_streams', {
                                   action: 'cell_unlocked',
                                   cell_id: cell_id,
                                   user_id: current_user.id
                                 })
  end

  def update_cell(data)
    cell_id = data['cell_id']
    stream_id = data['stream_id']
    field = data['field']
    value = data['value']

    # Verify user has lock on this cell
    unless cell_locked_by_user?(cell_id)
      reject
      return
    end

    # Find stream and check authorization
    stream = Stream.find(stream_id)

    # Check if user can modify streams
    unless current_user.can_modify_streams?
      transmit({ error: 'You are not authorized to edit streams' })
      return
    end

    # Sanitize field to prevent mass assignment
    allowed_fields = %w[title source link city state platform status orientation kind started_at ended_at]
    unless allowed_fields.include?(field)
      transmit({ error: 'Invalid field' })
      return
    end

    # Update the stream without triggering broadcasts or callbacks
    # We handle our own real-time updates via ActionCable
    begin
      # Use update_columns to completely skip all callbacks including after_commit
      success = false
      
      if %w[title source link city state platform orientation kind notes].include?(field)
        stream.update_columns(field => value, updated_at: Time.current)
        success = true
      elsif field == 'status'
        # Status needs special handling as it's an enum
        # Convert the display value to the enum key
        status_value = stream.class.statuses.key(value) || value.downcase
        stream.update_columns(status: status_value, updated_at: Time.current)
        success = true
      elsif %w[started_at ended_at].include?(field)
        # Handle datetime fields
        parsed_time = value.present? ? Time.parse(value) : nil
        stream.update_columns(field => parsed_time, updated_at: Time.current)
        success = true
      else
        transmit({ error: 'Invalid field for update' })
        return
      end

      if success
        # Broadcast update to all users via our channel
        ActionCable.server.broadcast('collaborative_streams', {
                                       action: 'cell_updated',
                                       cell_id: cell_id,
                                       stream_id: stream_id,
                                       field: field,
                                       value: value,
                                       user_id: current_user.id
                                     })

        # Auto-unlock after successful update
        unlock_cell(data)
      end
    rescue StandardError => e
      Rails.logger.error "Collaborative update failed: #{e.message}"
      transmit({ error: "Update failed: #{e.message}" })
    end
  end

  private

  def track_user_presence
    # Store user presence in Redis with user info as a single JSON string
    user_data = {
      id: current_user.id,
      name: current_user.display_name,
      color: user_color
    }.to_json
    
    # Store with expiration
    redis.setex("collaborative_streams:user:#{current_user.id}", 300, user_data)
    
    # Add to active users set
    redis.sadd('collaborative_streams:users', current_user.id)

    # Get all active users
    active_users = []
    active_user_ids = redis.smembers('collaborative_streams:users').to_a
    
    active_user_ids.each do |user_id|
      user_json = redis.get("collaborative_streams:user:#{user_id}")
      if user_json.nil?
        # Remove stale user from set
        redis.srem('collaborative_streams:users', user_id)
      else
        begin
          user_data = JSON.parse(user_json)
          active_users << {
            user_id: user_data['id'],
            user_name: user_data['name'],
            user_color: user_data['color']
          }
        rescue JSON::ParserError => e
          Rails.logger.error "Failed to parse user data: #{e.message}"
          redis.srem('collaborative_streams:users', user_id)
        end
      end
    end

    # Sort users by ID for consistent ordering
    active_users.sort_by! { |user| user[:user_id] }
    
    # Log for debugging
    Rails.logger.info "Active users for #{current_user.email}: #{active_users.map { |u| u[:user_name] }.join(', ')}"

    # Send the current user the list of all active users
    transmit({
      action: 'active_users_list',
      users: active_users
    })

    # Broadcast to others that this user joined
    ActionCable.server.broadcast('collaborative_streams', {
                                   action: 'user_joined',
                                   user_id: current_user.id,
                                   user_name: current_user.display_name,
                                   user_color: user_color
                                 })
  end

  def remove_user_presence
    redis.srem('collaborative_streams:users', current_user.id)
    redis.del("collaborative_streams:user:#{current_user.id}")

    # Broadcast user left
    ActionCable.server.broadcast('collaborative_streams', {
                                   action: 'user_left',
                                   user_id: current_user.id
                                 })
  end

  def lock_cell_for_user(cell_id)
    # Set lock with 30 second expiry
    redis.setex("collaborative_streams:cell:#{cell_id}:lock", 30, current_user.id)
  end

  def unlock_cell_for_user(cell_id)
    # Only unlock if this user has the lock
    return unless redis.get("collaborative_streams:cell:#{cell_id}:lock") == current_user.id.to_s

    redis.del("collaborative_streams:cell:#{cell_id}:lock")
  end

  def unlock_all_user_cells
    # Find all cells locked by this user and unlock them
    redis.keys('collaborative_streams:cell:*:lock').each do |key|
      next unless redis.get(key) == current_user.id.to_s

      cell_id = key.split(':')[2]
      redis.del(key)

      # Broadcast unlock
      ActionCable.server.broadcast('collaborative_streams', {
                                     action: 'cell_unlocked',
                                     cell_id: cell_id,
                                     user_id: current_user.id
                                   })
    end
  end

  def cell_locked_by_other?(cell_id)
    lock_user_id = redis.get("collaborative_streams:cell:#{cell_id}:lock")
    lock_user_id && lock_user_id != current_user.id.to_s
  end

  def cell_locked_by_user?(cell_id)
    redis.get("collaborative_streams:cell:#{cell_id}:lock") == current_user.id.to_s
  end

  def user_color
    user_color_for(current_user)
  end

  def user_color_for(user)
    # Generate consistent color for user based on ID
    colors = ['#FF6B6B', '#4ECDC4', '#45B7D1', '#FFA07A', '#98D8C8', '#F7DC6F', '#BB8FCE', '#85C1E2']
    colors[user.id % colors.length]
  end

  def redis
    @redis ||= Redis.new(url: ENV.fetch('REDIS_URL') { 'redis://redis:6379/1' })
  end
end
