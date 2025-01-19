class AddDetailsToTmdbEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :tmdb_entries, :adult, :boolean
    add_column :tmdb_entries, :backdrop_path, :string
    add_column :tmdb_entries, :original_language, :string
    add_column :tmdb_entries, :original_title, :string
    add_column :tmdb_entries, :popularity, :float
    add_column :tmdb_entries, :poster_path, :string
    add_column :tmdb_entries, :video, :boolean
    add_column :tmdb_entries, :vote_average, :float
    add_column :tmdb_entries, :vote_count, :integer

    create_table :genres do |t|
      t.string :name, null: false
    end

    create_table :tmdb_entries_genres, id: false do |t|
      t.references :tmdb_entry, null: false, foreign_key: true
      t.references :genre, null: false, foreign_key: true
    end
  end
end
