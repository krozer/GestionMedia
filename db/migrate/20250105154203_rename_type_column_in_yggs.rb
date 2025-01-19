class RenameTypeColumnInYggs < ActiveRecord::Migration[8.0]
  def change
    rename_column :yggs, :type, :sub_category
  end
end
