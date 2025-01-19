class CreateTmdbs < ActiveRecord::Migration[8.0]
  def change
    create_table :tmdbs, id: false do |t|
      t.integer :id, null: false, primary_key: true
      t.string :title, null: false
      t.date :release_date
      t.text :overview
      t.string :poster_path

      t.timestamps
    end
  end
end
