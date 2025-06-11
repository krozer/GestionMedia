class CreateTmdbTvEpisodes < ActiveRecord::Migration[8.0]
  def change
    create_table :tmdb_tv_episodes do |t|
      t.timestamps
    end
  end
end
