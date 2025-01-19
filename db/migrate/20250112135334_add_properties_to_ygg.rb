class AddPropertiesToYgg < ActiveRecord::Migration[8.0]
  def change
    add_column :yggs, :annee, :integer
    add_column :yggs, :saison, :integer
    add_column :yggs, :episode, :integer
    add_column :yggs, :source, :string
    add_column :yggs, :resolution, :string
    add_column :yggs, :langue, :string
    add_column :yggs, :codec, :string
    add_column :yggs, :audio, :string
    add_column :yggs, :canaux, :string
  end
end
