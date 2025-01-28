# app/models/plex_movie.rb
class PlexMovie < ApplicationRecord
  include TmdbSearchable
  include NameProperties
	# Relation vers la table pivot TmdbMovie
	belongs_to :tmdb_movie, optional: true

  scope :without_tmdb_id, -> { where(tmdb_id: nil) }
  
	# -- Exemple de méthode de classe "full_sync"
	def self.full_sync
	  plex_client = PlexApi.new
  
	  # 1) Récupérer toutes les sections "movie" dans Plex
	  all_sections = plex_client.library_sections
	  movie_sections = all_sections.select { |s| s["type"] == "movie" }
  
	  movie_sections.each do |section|
      puts "Synchronisation de la section : #{section['title']} (key=#{section['key']})"
    
      # 2) Récupérer tous les films de cette section
      items = plex_client.library_files(section["key"]) # => renvoie un tableau de "Video"
    
      # Conserver la liste des ratingKeys présents dans Plex
      media_id_in_plex = []
    
      items.each do |item|
        medias=PlexApi.normalize_to_array(item["Media"])

        medias.each do |media|
          part=PlexApi.normalize_to_array(media['Part'])
          plex_entry = PlexMovie.find_or_initialize_by(id: media["id"].to_i)
      
          if plex_entry.new_record?
            Rails.logger.info "Ajout du fichier #{part[0]['file']}"
            name_properties = PlexMovie.extract_properties_from_name(part[0]['file'])
            puts name_properties.inspect
            plex_entry.update!(
              id: media["id"].to_i,
              titre: item["title"],
              name: name_properties[:name],
              annee: item["year"],
              langue: name_properties[:langue],
              source: name_properties[:source],
              resolution: media["videoResolution"],
              codec:  media["videoCodec"],
              audio: media["audioCodec"],
              canaux: media["audioChannels"],
              size: part.map { |part| part["size"].to_i }.sum
            )
            plex_entry.search_tmdb
            plex_entry.save!
          end #if
        end #media
      end #items
    end #sections
  end #def
		# 5) (Optionnel) Supprimer les films qui ne sont plus dans Plex
		#   => on ne supprime QUE ceux qui appartiennent à la même section_key
		#      si on veut éviter tout conflit
		#   => S'il y a un champ "section_key" existant en base
		# On commente l'exemple, à activer si besoin :
		#
		# plex_movies_in_db = PlexMovie.where(section_key: section["key"])
		# plex_movies_in_db.each do |pm|
		#   unless rating_keys_in_plex.include?(pm.rating_key)
		#     pm.destroy
		#   end
		# end
  # Méthode de classe pour rechercher TMDb pour tous les films sans `tmdb_id`
  def self.search_tmdb_for_missing
    without_tmdb_id.find_each do |plex_movie|
      begin
        plex_movie.search_tmdb
        plex_movie.save! # Sauvegarde les changements si un `tmdb_id` a été trouvé
      rescue StandardError => e
        Rails.logger.error "Erreur lors de la recherche TMDb pour PlexMovie ID #{plex_movie.id}: #{e.message}"
      end
    end
  end
end
  