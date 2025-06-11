class CreateTmdbTvSeasons < ActiveRecord::Migration[6.1]
  def change
    create_table :tmdb_tv_seasons do |t|
      t.references :tmdb_tv, foreign_key: true
      t.integer :season_number
      t.string :title
      t.text :overview
      t.date :air_date
      t.integer :episode_count
      t.string :poster_path

      t.timestamps
    end
  end
end
