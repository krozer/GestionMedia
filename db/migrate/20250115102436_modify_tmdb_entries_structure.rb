class ModifyTmdbEntriesStructure < ActiveRecord::Migration[6.0]
  def change
    # remove_column :tmdb_entries, :id, :integer
    # add_column :tmdb_entries, :id, :integer, primary_key: true
  end
end