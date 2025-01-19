class CreateGenresTmdbEntriesJoinTable < ActiveRecord::Migration[6.0]
  def change
    create_table :genres_tmdb_entries, id: false do |t|
      t.references :tmdb_entry, null: false, foreign_key: true, index: true
      t.references :genre, null: false, foreign_key: true, index: true
    end
  end
end