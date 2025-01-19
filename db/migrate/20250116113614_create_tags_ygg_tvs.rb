class CreateTagsYggTvs < ActiveRecord::Migration[8.0]
  def change
    create_table :tags_ygg_tvs do |t|
      t.references :ygg_tv, null: false, foreign_key: { to_table: :ygg_tvs }
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end
  end
end
