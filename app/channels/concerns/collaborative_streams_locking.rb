# Locking helpers for collaborative stream editing.
module CollaborativeStreamsLocking
  extend ActiveSupport::Concern

  LOCK_TTL = 30

  def lock_cell_for_user(cell_id)
    redis.setex(lock_key(cell_id), LOCK_TTL, current_user.id)
  end

  def unlock_cell_for_user(cell_id)
    return unless redis.get(lock_key(cell_id)) == current_user.id.to_s

    redis.del(lock_key(cell_id))
  end

  def unlock_all_user_cells
    redis.keys("#{channel_name}:cell:*:lock").each do |key|
      next unless redis.get(key) == current_user.id.to_s

      cell_id = key.split(":")[2]
      redis.del(key)
      broadcast_cell_unlocked(cell_id)
    end
  end

  def cell_locked_by_other?(cell_id)
    lock_user_id = redis.get(lock_key(cell_id))
    lock_user_id && lock_user_id != current_user.id.to_s
  end

  def cell_locked_by_user?(cell_id)
    lock_user_id = redis.get(lock_key(cell_id))
    match = lock_user_id == current_user.id.to_s
    Rails.logger.info("Cell lock: lock_user_id=#{lock_user_id}, current_user_id=#{current_user.id}, match=#{match}")
    match
  end

  def lock_key(cell_id)
    "#{channel_name}:cell:#{cell_id}:lock"
  end
end
