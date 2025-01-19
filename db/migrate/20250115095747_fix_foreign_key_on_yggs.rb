class FixForeignKeyOnYggs < ActiveRecord::Migration[8.0]
  def change
    remove_foreign_key :yggs, :tmdb_entries if foreign_key_exists?(:yggs, :tmdb_entries)
    add_foreign_key :yggs, :tmdb_entries, column: :tmdb_id
  end
end
