class AddLocationToStreams < ActiveRecord::Migration[8.0]
  def change
    # Check if column already exists (for idempotency)
    unless column_exists?(:streams, :location_id)
      add_reference :streams, :location, foreign_key: true, index: true
    end
  end
end