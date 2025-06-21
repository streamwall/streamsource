class AddNotesToStreamsAndStreamers < ActiveRecord::Migration[8.0]
  def change
    # Notes columns already exist on streams and streamers
    # Just migrate the data and drop the notes table
    
    reversible do |dir|
      dir.up do
        # Migrate existing notes to the new fields
        if table_exists?(:notes)
          execute <<-SQL
            UPDATE streams 
            SET notes = COALESCE(streams.notes, '') || 
              CASE 
                WHEN streams.notes IS NOT NULL AND streams.notes != '' THEN E'\n\n'
                ELSE ''
              END ||
              (
                SELECT string_agg(content, E'\n\n' ORDER BY created_at DESC)
                FROM notes 
                WHERE notable_type = 'Stream' AND notable_id = streams.id
              )
            WHERE EXISTS (
              SELECT 1 FROM notes 
              WHERE notable_type = 'Stream' AND notable_id = streams.id
            );
          SQL
          
          execute <<-SQL
            UPDATE streamers 
            SET notes = COALESCE(streamers.notes, '') || 
              CASE 
                WHEN streamers.notes IS NOT NULL AND streamers.notes != '' THEN E'\n\n'
                ELSE ''
              END ||
              (
                SELECT string_agg(content, E'\n\n' ORDER BY created_at DESC)
                FROM notes 
                WHERE notable_type = 'Streamer' AND notable_id = streamers.id
              )
            WHERE EXISTS (
              SELECT 1 FROM notes 
              WHERE notable_type = 'Streamer' AND notable_id = streamers.id
            );
          SQL
        end
      end
    end
    
    # Drop the notes table
    drop_table :notes if table_exists?(:notes)
  end
end