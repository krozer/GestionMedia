class AddVuToTmdbMovies < ActiveRecord::Migration[8.0]
  def change
    add_column :tmdb_movies, :vu, :datetime
  end
end
