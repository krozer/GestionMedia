class AddCompleteFlagsToYggTv < ActiveRecord::Migration[8.0]
  def change
    add_column :ygg_tvs, :is_complete_season, :boolean
    add_column :ygg_tvs, :is_complete_series, :boolean
  end
end
