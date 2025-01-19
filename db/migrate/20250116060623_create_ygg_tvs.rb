class CreateYggTvs < ActiveRecord::Migration[8.0]
  def change
    create_table :ygg_tvs do |t|
      t.string :name
      t.string :url
      t.integer :sub_category
      t.integer :size
      t.datetime :added_date
      t.references :tmdb_tv, foreign_key: { to_table: :tmdb_tvs }
      t.integer :annee
      t.integer :saison
      t.integer :episode
      t.string :source
      t.string :resolution
      t.string :langue
      t.string :codec
      t.string :audio
      t.string :canaux
      t.string :titre

      t.timestamps
    end
  end
end
