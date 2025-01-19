class AddTmdbIdToYggs < ActiveRecord::Migration[8.0]
  def change
    add_column :yggs, :tmdb_id, :integer
    add_foreign_key :yggs, :tmdbs, column: :tmdb_id
  end
end