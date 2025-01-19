class CreateTmdbTvs < ActiveRecord::Migration[8.0]
  def change
    create_table :tmdb_tvs, id: false do |t|
      t.integer :id, primary_key: true
      t.string :name
      t.string :original_name
      t.date :first_air_date
      t.string :origin_country
      t.string :backdrop_path
      t.string :poster_path
      t.text :overview
      t.float :popularity
      t.float :vote_average
      t.integer :vote_count

      t.timestamps
    end
  end
end
