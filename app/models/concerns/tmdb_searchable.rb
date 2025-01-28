# app/models/concerns/tmdb_searchable.rb
module TmdbSearchable
	extend ActiveSupport::Concern
  def search_tmdb()
    return nil unless titre.present?
  
    # Rechercher une entrée TMDb existante
	existing_entry = TmdbMovie.where(
		"id = :tmdb_id OR title = :titre OR original_title = :titre",
		tmdb_id: tmdb_id,
		titre: titre
	  ).first
	puts "Tmdb find #{existing_entry.inspect}"
	if existing_entry
		self.update!(tmdb_id: existing_entry.id)
	end
    return existing_entry if existing_entry
  
    # Effectuer la recherche via l'API TMDb
    search = Tmdb::Search.movie(titre)
    sleep(0.5)
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
  
    if best_match[:score] > 0.77  || (sorted_results.size == 1 && best_match[:score] > 0.7) # Seuil minimal de confiance
      match_result = best_match[:result]
  
      # Vérifier ou créer une entrée TMDb
      tmdb_entry = TmdbMovie.create_or_update_tmdb_entry(match_result)
  
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