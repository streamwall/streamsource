# ActionCable channel for collaborative stream editing.
class CollaborativeStreamsChannel < ApplicationCable::Channel
  include CollaborativeStreamsPresence
  include CollaborativeStreamsLocking

  ALLOWED_FIELDS = %w[title source link city state platform status orientation kind started_at ended_at notes].freeze
  TEXT_FIELDS = %w[title source link city state platform orientation notes].freeze
  DATETIME_FIELDS = %w[started_at ended_at].freeze

  def subscribed
    stream_from channel_name
    track_user_presence
  end

  def unsubscribed
    remove_user_presence
    unlock_all_user_cells
  end

  def lock_cell(data)
    cell_id = data["cell_id"]

    if cell_locked_by_other?(cell_id)
      reject
      return
    end

    lock_cell_for_user(cell_id)
    broadcast_cell_locked(cell_id)
  end

  def unlock_cell(data)
    cell_id = data["cell_id"]
    return unless cell_locked_by_user?(cell_id)

    unlock_cell_for_user(cell_id)
    broadcast_cell_unlocked(cell_id)
  end

  def update_cell(data)
    cell_id, stream_id, field, value = extract_update_payload(data)
    log_update_request(data)

    return unless valid_update_request?(cell_id, field)

    stream = Stream.find(stream_id)
    return unless authorized_to_edit?
    return unless apply_stream_update?(stream, field, value)

    broadcast_cell_updated(cell_id, stream_id, field, value)
    unlock_cell(data)
  rescue StandardError => e
    Rails.logger.error("Collaborative update failed: #{e.message}")
    transmit_error("Update failed: #{e.message}")
  end

  private

  def channel_name
    "collaborative_streams"
  end

  def log_update_request(data)
    Rails.logger.info("CollaborativeStreamsChannel#update_cell: #{data.inspect}")
  end

  def apply_stream_update?(stream, field, value)
    attributes = build_update_attributes(stream, field, value)

    unless attributes
      transmit_error("Invalid field for update")
      return false
    end

    return true if stream.update(attributes)

    transmit_error(stream.errors.full_messages.to_sentence)
    false
  end

  def build_update_attributes(stream, field, value)
    case field
    when *TEXT_FIELDS
      { field => value }
    when "status"
      { "status" => normalize_status(stream, value) }
    when "kind"
      { "kind" => normalize_kind(stream, value) }
    when *DATETIME_FIELDS
      { field => parse_time(value) }
    end
  end

  def normalize_status(stream, value)
    stream.class.statuses.key(value) || value.to_s.downcase
  end

  def normalize_kind(stream, value)
    stream.class.kinds.key?(value) ? value : "video"
  end

  def parse_time(value)
    value.present? ? Time.zone.parse(value) : nil
  end

  def broadcast_cell_locked(cell_id)
    ActionCable.server.broadcast(channel_name, {
                                   action: "cell_locked",
                                   cell_id: cell_id,
                                   user_id: current_user.id,
                                   user_name: current_user.display_name,
                                   user_color: user_color,
                                 })
  end

  def broadcast_cell_unlocked(cell_id)
    ActionCable.server.broadcast(channel_name, {
                                   action: "cell_unlocked",
                                   cell_id: cell_id,
                                   user_id: current_user.id,
                                 })
  end

  def broadcast_cell_updated(cell_id, stream_id, field, value)
    ActionCable.server.broadcast(channel_name, {
                                   action: "cell_updated",
                                   cell_id: cell_id,
                                   stream_id: stream_id,
                                   field: field,
                                   value: value,
                                   user_id: current_user.id,
                                 })
  end

  def transmit_error(message)
    transmit(error: message)
  end

  def redis
    @redis ||= Redis.new(url: ENV.fetch("REDIS_URL") { "redis://redis:6379/1" })
  end

  def extract_update_payload(data)
    [data["cell_id"], data["stream_id"], data["field"], data["value"]]
  end

  def valid_update_request?(cell_id, field)
    unless cell_locked_by_user?(cell_id)
      Rails.logger.warn("Cell not locked by user: #{cell_id}")
      reject
      return false
    end

    unless ALLOWED_FIELDS.include?(field)
      transmit_error("Invalid field")
      return false
    end

    true
  end

  def authorized_to_edit?
    return true if current_user.can_modify_streams?

    transmit_error("You are not authorized to edit streams")
    false
  end
end
