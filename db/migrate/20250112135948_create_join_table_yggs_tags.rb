class CreateJoinTableYggsTags < ActiveRecord::Migration[8.0]
  def change
    create_join_table :yggs, :tags do |t|
      # t.index [:ygg_id, :tag_id]
      # t.index [:tag_id, :ygg_id]
    end
  end
end
