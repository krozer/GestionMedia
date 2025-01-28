class CreatePlexMovies < ActiveRecord::Migration[8.0]
  def change
    create_table :plex_movies do |t|
      t.string  :rating_key
      t.string  :plex_guid
      t.string  :title
      t.integer :size
      t.string  :resolution
      t.string  :language
      t.string  :audio
      t.string  :section_key      # si vous souhaitez savoir de quelle bibliothèque Plex
      t.integer :tmdb_id          # référence vers tmdb_movies.tmdb_id

      t.timestamps
    end

    # Clé étrangère : on pointe "tmdb_id" vers la colonne "tmdb_id" de "tmdb_movies"
    add_foreign_key :plex_movies, :tmdb_movies, column: :tmdb_id
    add_index :plex_movies, :rating_key, unique: true  # si vous voulez un rating_key unique
  end
end
