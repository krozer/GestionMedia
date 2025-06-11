class YggTv < ApplicationRecord
  self.primary_key = 'id'
  require 'amatch'
  include NameCleaner
  include TmdbSearchable

  # Relations
  belongs_to :sub_category, foreign_key: 'sub_category', primary_key: 'code', optional: true
  belongs_to :tmdb_tv, optional: true, class_name: 'TmdbTv'
  has_and_belongs_to_many :tags, join_table: :tags_ygg_tvs

  # Extraction des propriétés à partir du nom
  def extract_properties_from_name
    if name.present?
      self.annee      = name[/(19\d{2}|20\d{2})/, 1]&.to_i
      self.saison     = name[/[ ._-](S|Saison|Season)[ ._-]?(?<saison>\d{1,2})(?=\.|\s|E|$)/i, :saison]&.to_i
      self.episode    = name[/E(?<episode>\d{1,4})(?=\.|\s|$)/i, :episode]&.to_i
      self.resolution = name[/(1080p|720p|2160p|4K)/i, 1]
      
      keywords = %w[VFF MULTI TRUEFRENCH VOSTFR VOF VF2 VFI FRENCH VF]
      matches  = name.scan(/(#{keywords.join('|')})/i).flatten
      self.langue = keywords.find { |keyword| matches.include?(keyword) }
      
      self.codec    = name[/(x264|x265|H264|H265|AV1|HEVC)/i, 1]&.upcase
      self.audio    = name[/(DTS|DDP|AC3|AAC|E-AC3)/i, 1]&.upcase
      self.canaux   = name[/(5\.1|7\.1|2\.0)/, 1]
      self.source   = name[/(BluRay|WEB(-)?DL|HDTV|HDRip|WEBRip|BDRIP|NF.WEB|AMZN.WEB|HDR|WEB)/i, 1]&.upcase
      
      self.titre = extract_title_from_name

      # **Ajout des nouvelles colonnes**

      self.is_complete_series = complete_series?
      if self.is_complete_series
        self.is_complete_season = false
      else
        self.is_complete_season = complete_season?
      end
      

      if self.saison.blank? && self.episode.blank?
        self.is_complete_series = true
      end

      assign_tags_from_database
    end
  end

  def extract_title_from_name
    return nil unless name.present?

    cleaned_name = name.dup

    # Détection du format "Titre (AAAA)"
    match = cleaned_name.match(/^(.+?).\((19\d{2}|20\d{2})\)/)
    if match
      title = match[1].strip
      year = match[2]
      return clean_name(title)
    end

    # Suppression des métadonnées
    metadata_patterns = [
      /(19\d{2}|20\d{2})/, /S\d{1,2}/i, /E\d{1,4}/i, 
      /(1080p|720p|2160p|4K)/i, /(MULTI|TRUEFRENCH|VOSTFR|VOF|VFF|VF2|VFI|FRENCH|VF)/i, 
      /(x264|x265|H264|H265|AV1|HEVC)/i, /(DTS|DDP|AC3|AAC|E-AC3)/i, 
      /(BluRay|WEB(-)?DL|HDTV|HDRip|WEBRip|BDRIP|NF.WEB|AMZN.WEB|HDR|WEB)/i, 
      /(PROPER|REPACK|UNRATED|EXTENDED|DIRECTOR.S.CUT|INTEGRALE|COMPLETE|INTERNAL|10bits?)/i
    ]

    first_metadata_position = metadata_patterns.map { |pattern| cleaned_name =~ pattern }.compact.min
    cleaned_name = cleaned_name[0...first_metadata_position] if first_metadata_position

    clean_name(cleaned_name).strip
  end

  # Associer les tags à l'instance actuelle
  def assign_tags_from_database
    tag_patterns = Tag.all.index_by(&:name)
    matching_tags = tag_patterns.values.select do |tag|
      name.match?(Regexp.new(tag.pattern, Regexp::IGNORECASE))
    end
    self.tags = matching_tags
  end

  # Recherche TMDb
  def search_tmdb
    return nil unless titre.present?
  
    # Vérifier si un TMDb ID existe déjà
    existing_entry = TmdbTv.where(
      "id = :tmdb_id OR name = :titre OR original_name = :titre",
      tmdb_id: tmdb_tv_id,
      titre: titre
    ).first
  
    if existing_entry
      self.update!(tmdb_tv_id: existing_entry.id)
      return existing_entry
    end
  
    # Recherche via l'API TMDb
    search = Tmdb::Search.tv(titre)
    sleep(0.5)
    results = search.results
  
    return nil if results.blank?
  
    # Score de pertinence pour chaque résultat
    scored_results = results.map do |result|
      {
        result: result,
        score: calculate_match_score(result)
      }
    end
  
    # Trier par score décroissant
    sorted_results = scored_results.sort_by { |entry| -entry[:score] }
  
    # Si ex-aequo, ignorer
    return nil if sorted_results.size > 1 && sorted_results[0][:score] == sorted_results[1][:score]
  
    best_match = sorted_results.first
  
    if best_match[:score] > 0.77 || (sorted_results.size == 1 && best_match[:score] > 0.7)
      match_result = best_match[:result]
      tmdb_entry = TmdbTv.create_or_update_tmdb_entry(match_result)
  
      self.update!(tmdb_id: tmdb_entry.id)
      Rails.logger.info "YggTv ID #{id} associé à TMDb ID #{tmdb_entry.id}."
  
      return tmdb_entry
    else
      Rails.logger.info "Aucune correspondance trouvée pour '#{titre}' (score: #{best_match[:score]})."
      nil
    end
  end
  

  # Mise à jour des données TMDb pour une entrée spécifique
  def self.update_tmdb_entry(entry_id)
    begin
      puts "ID #{entry_id}"
      details = Tmdb::TV.detail(entry_id, language: "fr")
      return unless details

      tmdb_entry = TmdbTv.find_or_initialize_by(id: details.id)
      tmdb_entry.update!(
        title: details.name,
        original_title: details.original_name,
        release_date: details.first_air_date,
        overview: details.overview,
        popularity: details.popularity,
        poster_path: details.poster_path,
        backdrop_path: details.backdrop_path,
        vote_average: details.vote_average,
        vote_count: details.vote_count,
        number_of_episodes: details.number_of_episodes,
        number_of_seasons: details.number_of_seasons,
        origin_country: details.origin_country.join(", "),
        status: details.status
      )
    
      Rails.logger.info "Détails TMDb mis à jour pour #{tmdb_entry.title}."
    
      # Associer la série avec YggTv
      self.update!(tmdb_tv: tmdb_entry)
    
      # Mise à jour des genres
      update_genres(details)
    
      # Mettre à jour les saisons et épisodes
      update_tmdb_seasons_and_episodes
    
      tmdb_entry

      puts "Série ID #{entry_id} mise à jour avec succès."
    rescue Tmdb::Error => e
      puts "Erreur pour la série ID #{entry_id} : #{e.message}. Ignorée."
    rescue ActiveRecord::RecordInvalid => e
      puts "Erreur de validation pour la série ID #{entry_id} : #{e.message}. Ignorée."
    rescue StandardError => e
      puts "Erreur inattendue pour la série ID #{entry_id} : #{e.message}. Ignorée."
    end
  end

  def update_genres(details)
    details.genres.each do |genre_data|
      genre = Genre.find_or_create_by!(id: genre_data.id, name: genre_data.name)
      GenresTmdbTv.find_or_create_by!(tmdb_tv: self.tmdb_tv, genre: genre)
    end
  end
  
  def update_tmdb_seasons_and_episodes
    return unless tmdb_tv
  
    (1..tmdb_tv.number_of_seasons).each do |season_number|
      season_details = Tmdb::Tv::Season.detail(tmdb_tv.id, season_number)
  
      next unless season_details
  
      season = TmdbTvSeason.find_or_initialize_by(tmdb_tv: tmdb_tv, season_number: season_details.season_number)
      season.update!(
        title: season_details.name,
        overview: season_details.overview,
        air_date: season_details.air_date,
        episode_count: season_details.episodes.size,
        poster_path: season_details.poster_path
      )
  
      Rails.logger.info "Saison #{season.season_number} mise à jour."
  
      update_tmdb_episodes(season_details, season)
    end
  end

  def update_tmdb_episodes(season_details, season)
    season_details.episodes.each do |episode_data|
      episode = TmdbTvEpisode.find_or_initialize_by(tmdb_tv_season: season, episode_number: episode_data.episode_number)
      episode.update!(
        title: episode_data.name,
        overview: episode_data.overview,
        air_date: episode_data.air_date,
        runtime: episode_data.runtime,
        still_path: episode_data.still_path,
        vote_average: episode_data.vote_average,
        vote_count: episode_data.vote_count
      )
  
      Rails.logger.info "Épisode #{episode.episode_number} - #{episode.title} mis à jour."
    end
  end
  


  # Recherche de toutes les séries sans ID TMDb
  def self.search_all_tmdb_id
    where(tmdb_tv_id: nil).find_each do |ygg_tv|
      ygg_tv.search_tmdb
    end
  end

  # Mise à jour des propriétés pour toutes les entrées
  def self.update_all_properties
    all.find_each do |ygg_tv|
      ygg_tv.extract_properties_from_name
      ygg_tv.save!
      puts "Mise à jour des propriétés pour : #{ygg_tv.name}"
    end
  end

  # Conversion en taille lisible
  def human_readable_size
    return "N/A" if size.blank?

    units = %w[B Ko Mo Go To]
    value = size.to_f
    index = 0

    while value >= 1024 && index < units.size - 1
      value /= 1024
      index += 1
    end

    "#{value.round(2)} #{units[index]}"
  end

  def complete_season?
    return false unless name.present?
  
    # Si le nom contient "S01" mais **PAS** "E01", "E02", etc., alors c'est une saison complète
    if name.match?(/[ ._-](S|Saison|Season)[ ._-]?\d{1,2}/i) && !name.match?(/(S|Saison|Season)[ ._-]?\d{1,2}.*E\d{1,4}/i)
      return true
    end
  
    # Vérification avec d'autres motifs
    patterns = [
      /[ ._-]S\d{1,2}(\s|-|_)?COMPLETE/i,  # Ex: "S01 COMPLETE"
      /Saison\s\d+\sComplète/i,      # Ex: "Saison 1 Complète"
      /S\d{1,2}E\d{2}-S\d{1,2}E\d{2}/i  # Ex: "S01E01-S01E10"
    ]
  
    return true if patterns.any? { |pattern| name.match?(pattern) }
  
    # Vérification avec TMDb (optionnel)
    # season_complete_based_on_tmdb?
    false
  end
  
  

  def complete_series?
    return false unless name.present?
  
    # Vérifier si le fichier contient des mots-clés de séries complètes **sans mention de saison/épisode**
    if name.match?(/(Int[éeèëê]grale|Compl[èéêë]t[e]?|Total)/i) && !name.match?(/[ ._-](S|Saison|Season)[ ._-]?\d{1,2}|E\d{1,4}/i)
      return true
    end
  
    # Vérification avec plusieurs formats de "série complète"
    patterns = [
      /COMPLETE SERIES/i,       # "COMPLETE SERIES"
      /SERIE COMPL[èéêë]TE/i,   # "Série complète" avec accents
      /S\d+-S\d+/i              # Plages de saisons "S1-S8"
    ]
  
    return true if patterns.any? { |pattern| name.match?(pattern) }
  
    false
  end
  
  
  private

  # Nom de la catégorie via la sous-catégorie
  def category_name
    sub_category&.category&.name
  end
end
