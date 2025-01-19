class RenameTagsYggsToTagsYggMovies < ActiveRecord::Migration[8.0]
  def change
    rename_table :tags_yggs, :tags_ygg_movies
  end
end
