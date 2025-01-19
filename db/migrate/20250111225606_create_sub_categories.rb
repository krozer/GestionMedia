class CreateSubCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :sub_categories do |t|
      t.integer :code, null: false           # Colonne code
      t.string :label, null: false           # Colonne label

      t.timestamps
    end

    # Ajouter une contrainte d'unicité sur la colonne code
    add_index :sub_categories, :code, unique: true
  end
end
