class CreateGenresTmdbTvs < ActiveRecord::Migration[8.0]
  def change
    create_table :genres_tmdb_tvs do |t|
      t.references :tmdb_tv, null: false, foreign_key: true
      t.references :genre, null: false, foreign_key: true

      t.timestamps
    end
  end
end
