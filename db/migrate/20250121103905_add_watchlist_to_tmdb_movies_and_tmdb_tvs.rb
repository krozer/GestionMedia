class AddWatchlistToTmdbMoviesAndTmdbTvs < ActiveRecord::Migration[8.0]
  def change
    add_column :tmdb_movies, :watchlist, :boolean, default: false
    add_column :tmdb_tvs, :watchlist, :boolean, default: false
  end
end
