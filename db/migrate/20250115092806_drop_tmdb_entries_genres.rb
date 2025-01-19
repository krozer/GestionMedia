class DropTmdbEntriesGenres < ActiveRecord::Migration[8.0]
  def change
    drop_table :tmdb_entries_genres
  end
end
