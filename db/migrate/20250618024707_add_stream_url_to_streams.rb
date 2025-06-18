class AddStreamUrlToStreams < ActiveRecord::Migration[8.0]
  def change
    add_reference :streams, :stream_url, null: true, foreign_key: true, index: true
  end
end
