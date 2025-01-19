class CreateYggs < ActiveRecord::Migration[8.0]
  def change
    create_table :yggs, id: false do |t|
      t.integer :id, primary_key: true
      t.string :name
      t.string :url
      t.integer :type
      t.integer :size
      t.date :added_date
      t.date :created_date

      t.timestamps
    end
  end
end
