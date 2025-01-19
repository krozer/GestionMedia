class UpdateYggsTable < ActiveRecord::Migration[8.0]
  def change
        # Supprimer la colonne created_date
        remove_column :yggs, :created_date, :date

        # Modifier le type de la colonne added_date de date à datetime
        change_column :yggs, :added_date, :datetime
  end
end
