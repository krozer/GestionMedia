class DropOldPlexMovies < ActiveRecord::Migration[8.0]
  def change
    drop_table :plex_movies, if_exists: true
  end
end
