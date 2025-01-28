class ReCreatePlexMovies < ActiveRecord::Migration[8.0]
  def change
    create_table :plex_movies, id: false do |t|
      t.integer :id, primary_key: true, null: false # Clé primaire non auto-incrémentée
      t.string :titre, null: false                 # Nouveau champ 'titre'
      t.string :name                               # Nouveau champ 'name'
      t.integer :annee                             # Année du film
      t.string :langue                             # Langue
      t.string :source                             # Source
      t.string :resolution                         # Résolution
      t.string :codec                              # Codec vidéo
      t.string :audio                              # Type d'audio
      t.string :canaux                             # Nombre de canaux audio
      t.integer :size                              # Taille du fichier
      t.integer :tmdb_id, null: true               # Référence vers TMDB
      t.timestamps                                 # Champs created_at et updated_at
    end

    # Ajout d'une contrainte de clé étrangère vers la table tmdb_movies
    add_foreign_key :plex_movies, :tmdb_movies, column: :tmdb_id
  end
end
