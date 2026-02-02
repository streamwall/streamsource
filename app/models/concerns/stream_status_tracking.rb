# Status tracking and time helpers for streams.
module StreamStatusTracking
  extend ActiveSupport::Concern

  included do
    before_save :update_last_checked_at, if: :status_changed?
    before_save :update_last_live_at, if: -> { status_changed? && live? }
    before_save :set_started_at, if: -> { status_changed? && live? && started_at.blank? }
  end

  def duration_in_words
    return nil unless duration

    seconds = duration.to_i
    hours = seconds / 3600
    minutes = (seconds % 3600) / 60

    hours.positive? ? "#{hours}h #{minutes}m" : "#{minutes}m"
  end

  def mark_as_live!
    updates = {
      status: "Live",
      last_checked_at: Time.current,
      last_live_at: Time.current,
    }
    updates[:started_at] = Time.current if started_at.blank?
    update!(updates)
  end

  def mark_as_offline!
    update!(status: "Offline", last_checked_at: Time.current)
    archive! if should_archive?
  end

  def mark_as_unknown!
    update!(status: "Unknown", last_checked_at: Time.current)
    archive! if should_archive?
  end

  def archive!
    return if is_archived?

    update!(
      is_archived: true,
      ended_at: ended_at || last_checked_at || Time.current,
    )
  end

  def should_archive?
    return false if is_archived? || live?

    last_checked_at.present? && last_checked_at < 30.minutes.ago
  end

  def duration
    return nil if started_at.blank?

    (ended_at || Time.current) - started_at
  end

  def broadcast_time_updates
    ActionCable.server.broadcast("collaborative_streams", {
                                   action: "stream_updated",
                                   stream_id: id,
                                   last_checked_at: last_checked_at&.iso8601,
                                   last_live_at: last_live_at&.iso8601,
                                 })
  end

  private

  def update_last_checked_at
    self.last_checked_at = Time.current
  end

  def update_last_live_at
    self.last_live_at = Time.current
  end

  def set_started_at
    self.started_at = Time.current
  end
end
