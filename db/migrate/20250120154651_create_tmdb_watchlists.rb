class CreateTmdbWatchlists < ActiveRecord::Migration[8.0]
  def change
    create_table :tmdb_watchlists do |t|
      t.integer :tmdb_id
      t.string :media_type
      t.string :title
      t.date :release_date
      t.text :overview
      t.string :poster_path

      t.timestamps
    end
  end
end
