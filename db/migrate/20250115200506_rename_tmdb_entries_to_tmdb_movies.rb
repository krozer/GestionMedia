class RenameTmdbEntriesToTmdbMovies < ActiveRecord::Migration[7.0]
  def change
    # remove_foreign_key :genres_tmdb_entries, column: :tmdb_entry_id
    rename_table :tmdb_entries, :tmdb_movies
    rename_table :genres_tmdb_entries, :genres_tmdb_movies
    rename_column :genres_tmdb_movies, :tmdb_entry_id, :tmdb_movie_id
    rename_table :yggs, :yggs_movies
    add_foreign_key :yggs_movies, :tmdb_movies, column: :tmdb_id, primary_key: :id
    #add_foreign_key :genres_tmdb_movies, :tmdb_movies, column: :tmdb_movies_id, primary_key: :id

  end
end
