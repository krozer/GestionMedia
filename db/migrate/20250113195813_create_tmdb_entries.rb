class CreateTmdbEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :tmdb_entries, id: false do |t| # Désactive l'ID par défaut
      t.primary_key :id, :integer
      t.string :title
      t.date :release_date
      t.text :overview

      t.timestamps
    end
  end
end
