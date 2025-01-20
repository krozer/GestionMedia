class YggMovie < ApplicationRecord
  self.primary_key = 'id'
  require 'amatch'
  include NameCleaner # Inclusion du module
	# Relations
	belongs_to :sub_category, foreign_key: 'sub_category', primary_key: 'code', optional: true
	belongs_to :tmdb_movie, foreign_key: 'tmdb_id', class_name: 'TmdbMovie', optional: true
  has_and_belongs_to_many :tags, join_table: :tags_ygg_movies

	# Extract properties from the name field
	def extract_properties_from_name
		if name.present?
			self.annee = name[/(19\d{2}|20\d{2})/, 1]&.to_i
			self.saison = name[/S(?<saison>\d{1,2})(?=\.|\s|E|$)/i, :saison]&.to_i
			self.episode = name[/E(?<episode>\d{1,2})(?=\.|\s|$)/i, :episode]&.to_i
			self.resolution = name[/(1080p|720p|2160p|4K)/i, 1]
			self.langue = name[/(MULTI|TRUEFRENCH|FRENCH|VOSTFR|VOF|VFF|VF2|VFI|VF)/i, 1]&.upcase
			self.codec = name[/(x264|x265|H264|H265|AV1|HEVC)/i, 1]&.upcase
			self.audio = name[/(DTS|DDP|AC3|AAC|E-AC3)/i, 1]&.upcase
			self.canaux = name[/(5\.1|7\.1|2\.0)/, 1]
			self.source = name[/(BluRay|WEB(-)?DL|HDTV|HDRip|WEBRip|BDRIP|NF.WEB|AMZN.WEB|HDLight|HDR|WEB)/i, 1]&.upcase
			# Extraire le titre principal
			self.titre = extract_title_from_name
			# Associate tags for unstructured attributes
			assign_tags_from_database
		end
	end
	def extract_title_from_name
		return nil unless name.present?
	  
		cleaned_name = name.dup
	  
		# Étape 1 : Trouver les limites du titre
		# Identifier la position des éléments qui marquent le début des métadonnées
		metadata_patterns = [
		  /(19\d{2}|20\d{2})/,           # Année
		  /S\d{1,2}/i,
		  /E\d{1,2}/i,          # Saison/Episode
		  /(1080p|720p|2160p|4K)/i,     # Résolution
		  /(MULTI|TRUEFRENCH|FRENCH|VOSTFR|VOF|VFF|VF2|VFI|VF)/i, # Langue
		  /(x264|x265|H264|H265|AV1|HEVC)/i, # Codec
		  /(DTS|DDP|AC3|AAC|E-AC3)/i,    # Audio
		  /(BluRay|WEB(-)?DL|HDTV|HDRip|WEBRip|BDRIP|NF.WEB|AMZN.WEB|HDLight|HDR|WEB)/i, # Source
		  /(PROPER|REPACK|UNRATED|EXTENDED|DIRECTOR.S.CUT|iNTEGRALE|Intégrale|Custom|COMPLETE|iNTERNAL|10bits?)/i # Tags spéciaux
		]
	  
		# Trouver la première occurrence d'un motif à supprimer
		first_metadata_position = metadata_patterns.map { |pattern| cleaned_name =~ pattern }.compact.min
	  
		# Si un motif est trouvé, tronquer la chaîne
		if first_metadata_position
		  cleaned_name = cleaned_name[0...first_metadata_position]
		end
	  
    cleaned_name=clean_name(cleaned_name)
	  
		# Étape 3 : Suppression des doublons éventuels
		words = cleaned_name.split
		cleaned_name = words.uniq.join(' ')
	  
		# Étape 4 : Retirer les résidus éventuels en fin de chaîne
		cleaned_name.gsub!(/\s+$/, '')
	  
		cleaned_name
	end
	
	# Associate tags to the current Ygg instance based on tag names found in the name
  def assign_tags_from_database
    tag_patterns = Tag.all.index_by(&:name)
    matching_tags = tag_patterns.values.select do |tag|
      name.match?(Regexp.new(tag.pattern, Regexp::IGNORECASE))
    end
    self.tags = matching_tags
  end
  # Méthode de classe pour extraire les titres
  def self.extract_titles_for_all(limit: nil, offset: nil)
    query = self.all
    query = query.offset(offset) if offset
    query = query.limit(limit) if limit

    query.map do |ygg|
      { id: ygg.id, title: ygg.extract_title_from_name }
    end
  end
    # Méthode de classe pour appliquer extract_properties_from_name à tous les enregistrements
	def self.update_all_properties
	  all.find_each do |ygg|
		  ygg.extract_properties_from_name
		  ygg.save! # Sauvegarde les modifications dans la base de données
		  puts "Mise à jour des propriétés pour : #{ygg.name}"
	  end
	end

  def self.update_tmdb_entry(entry_id)
    begin
      # Récupérer les détails (film ou série)
      details=Tmdb::Movie.detail(entry_id, language: "fr")


      # Initialiser ou trouver l'enregistrement dans la base de données
      tmdb_entry = TmdbMovie.find_or_initialize_by(id: entry_id)

      # Mettre à jour les champs communs
      tmdb_entry.update!(
        title: details.title || details.name,
        release_date: details.release_date || details.first_air_date,
        overview: details.overview,
        adult: details.adult,
        backdrop_path: details.backdrop_path,
        original_language: details.original_language,
        original_title: details.original_title || details.original_name,
        popularity: details.popularity,
        poster_path: details.poster_path,
        video: details.respond_to?(:video) ? details.video : nil,
        vote_average: details.vote_average,
        vote_count: details.vote_count,
        origin_country: details.origin_country&.join(", ")
      )

      # Mettre à jour les genres
      match_result.genre_ids.each do |genre_id|
        genre = Genre.find_or_create_by!(id: genre_id)
        GenresTmdbMovie.find_or_create_by!(tmdb_movie: tmdb_movie, genre: genre)
      end
    

      puts "#{type.to_s.capitalize} ID #{entry_id} mis à jour avec succès."
    rescue Tmdb::Error => e
      puts "Erreur pour le #{type} ID #{entry_id} : #{e.message}. Ignoré."
    rescue ActiveRecord::RecordInvalid => e
      puts "Erreur de validation pour le #{type} ID #{entry_id} : #{e.message}. Ignoré."
    rescue StandardError => e
      puts "Erreur inattendue pour le #{type} ID #{entry_id} : #{e.message}. Ignoré."
    end
  end

  def search_tmdb
    return nil unless titre.present?
  
    # Rechercher une entrée TMDb existante
    existing_entry = TmdbMovie.find_by(title: titre, id: tmdb_id)
    return existing_entry if existing_entry
  
    # Effectuer la recherche via l'API TMDb
    search = Tmdb::Search.movie(titre)
    results = search.results
  
    return nil if results.blank?
  
    # Calculer les scores de pertinence pour chaque résultat
    scored_results = results.map do |result|
      {
        result: result,
        score: calculate_match_score(result)
      }
    end
  
    # Trier les résultats par score décroissant
    sorted_results = scored_results.sort_by { |entry| -entry[:score] }
  
    # Détecter les ex-aequo
    if sorted_results.size > 1 && sorted_results[0][:score] == sorted_results[1][:score]
      Rails.logger.info "Ex-aequo détecté pour '#{titre}'. Aucun résultat sélectionné."
      return nil
    end
  
    best_match = sorted_results.first
  
    if best_match[:score] > 0.8  || (sorted_results.size == 1 && best_match[:score] > 0.7) # Seuil minimal de confiance
      match_result = best_match[:result]
  
      # Vérifier ou créer une entrée TMDb
      tmdb_entry = create_or_update_tmdb_entry(match_result)
  
      # Mettre à jour l'enregistrement YGG avec l'ID TMDb
      self.update!(tmdb_id: tmdb_entry.id)
  
      Rails.logger.info "YggMovie ID #{id} associé à TMDb ID #{tmdb_entry.id}."
      return tmdb_entry
    else
      Rails.logger.info "Aucune correspondance suffisamment pertinente pour '#{titre}' : score '#{best_match[:score]}'."
      nil
    end
  end
  
  def calculate_match_score(result)
    # Calculer la similarité avec `title` et `original_title`
    title_similarity = similarity(titre, result.title)
    original_title_similarity = similarity(titre, result.original_title || '')
  
    # Prendre le meilleur score entre `title` et `original_title`
    best_title_similarity = [title_similarity, original_title_similarity].max
  
    # Calculer la proximité de date
    date_proximity = release_date_proximity(result.release_date, annee)
  
    # Calculer le score de popularité (normalisé entre 0 et 1)
    popularity_score = result.popularity.to_f / 100
    popularity_score = 1.0 if popularity_score > 1.0
  
    # Calculer le score des votes
    vote_score = result.vote_count.to_f / 10_000
    vote_score = 1.0 if vote_score > 1.0
  
    # Bonus pour la présence de `backdrop_path` et `poster_path`
    media_bonus = 0
    media_bonus += 0.1 if result.backdrop_path.present?
    media_bonus += 0.1 if result.poster_path.present?
  
    # Calcul du score final avec pondération
    best_title_similarity * 0.5 +
      date_proximity * 0.2 +
      popularity_score * 0.15 +
      vote_score * 0.1 +
      media_bonus
  end
  

  def create_or_update_tmdb_entry(result)
    tmdb_entry = TmdbMovie.find_or_initialize_by(id: result.id)
    if tmdb_entry.new_record?
      tmdb_entry.update!(
        title: result.title,
        release_date: result.release_date,
        overview: result.overview,
        adult: result.adult,
        backdrop_path: result.backdrop_path,
        original_language: result.original_language,
        original_title: result.original_title,
        popularity: result.popularity,
        poster_path: result.poster_path,
        video: result.respond_to?(:video) ? result.video : nil,
        vote_average: result.vote_average,
        vote_count: result.vote_count
      )
  
      # Mettre à jour les genres
      if result.genre_ids.present?
        result.genre_ids.each do |genre_id|
          genre = Genre.find_or_create_by!(id: genre_id)
          GenresTmdbMovie.find_or_create_by!(tmdb_movie: tmdb_entry, genre: genre)
        end
      end
  
      Rails.logger.info "Nouvelle entrée TMDb créée : #{result.title} (TMDb ID: #{result.id})"
    end
    tmdb_entry
  end
  

  def self.search_all_tmdb_id
    where(tmdb_id: nil).find_each do |ygg_movie|
      ygg_movie.search_tmdb
    end
  end
  def human_readable_size
    return "N/A" if size.blank?

    units = %w[B Ko Mo Go To]
    value = size.to_f
    index = 0

    while value >= 1024 && index < units.size - 1
      value /= 1024
      index += 1
    end

    # Retourne la taille avec 2 décimales et l'unité correspondante
    "#{value.round(2)} #{units[index]}"
  end
  private

  # Récupère le nom de la catégorie via la sous-catégorie
  def category_name
    sub_category&.category&.name
  end

  # Calcul de la similarité des titres
  def similarity(str1, str2)
    return 0.0 if str1.blank? || str2.blank?

    str1=clean_name(str1)
    str2=clean_name(str2)
    matcher = Amatch::JaroWinkler.new(str1)
    matcher.match(str2) # Retourne un score entre 0.0 (aucune similarité) et 1.0 (identique)
  end

  # Calcul de la proximité des dates de sortie
  def release_date_proximity(api_date, local_year)
    return 0 if api_date.blank? || local_year.blank?
    (Date.parse(api_date).year - local_year.to_i).abs <= 1 ? 1.0 : 0.0
  end
end