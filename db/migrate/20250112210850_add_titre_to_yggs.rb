class AddTitreToYggs < ActiveRecord::Migration[8.0]
  def change
    add_column :yggs, :titre, :string
  end
end
