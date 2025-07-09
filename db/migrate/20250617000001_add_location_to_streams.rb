class AddLocationToStreams < ActiveRecord::Migration[8.0]
  def change
    add_reference :streams, :location, foreign_key: true, index: true
  end
end