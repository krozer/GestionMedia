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
      self.saison     = name[/S(?<saison>\d{1,2})(?=\.|\s|E|$)/i, :saison]&.to_i
      self.episode    = name[/E(?<episode>\d{1,2})(?=\.|\s|$)/i, :episode]&.to_i
      self.resolution = name[/(1080p|720p|2160p|4K)/i, 1]
      
      keywords = %w[VFF MULTI TRUEFRENCH VOSTFR VOF VF2 VFI FRENCH VF]
      matches  = name.scan(/(#{keywords.join('|')})/i).flatten
      self.langue = keywords.find { |keyword| matches.include?(keyword) }
      
      self.codec    = name[/(x264|x265|H264|H265|AV1|HEVC)/i, 1]&.upcase
      self.audio    = name[/(DTS|DDP|AC3|AAC|E-AC3)/i, 1]&.upcase
      self.canaux   = name[/(5\.1|7\.1|2\.0)/, 1]
      self.source   = name[/(BluRay|WEB(-)?DL|HDTV|HDRip|WEBRip|BDRIP|NF.WEB|AMZN.WEB|HDR|WEB)/i, 1]&.upcase
      
      self.titre = extract_title_from_name
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

    search = Tmdb::Search.tv(titre)
    results = search.results

    scored_results = results.map do |result|
      title_similarity = similarity(titre, result.name)
      date_proximity = release_date_proximity(result.first_air_date, annee)
      score = title_similarity * 0.7 + date_proximity * 0.3
      { result: result, score: score }
    end

    sorted_results = scored_results.sort_by { |entry| -entry[:score] }
    return nil if sorted_results.size > 1 && sorted_results[0][:score] == sorted_results[1][:score]

    best_match = sorted_results.first
    best_match && best_match[:score] > 0.5 ? best_match[:result] : nil
  end

  # Mise à jour des données TMDb pour une entrée spécifique
  def self.update_tmdb_entry(entry_id)
    begin
      puts "ID #{entry_id}"
      details = Tmdb::TV.detail(entry_id, language: "fr")

      tmdb_entry = TmdbTv.find_or_initialize_by(id: entry_id)
      tmdb_entry.update!(
        title: details.name,
        release_date: details.first_air_date,
        overview: details.overview,
        original_language: details.original_language,
        original_title: details.original_name,
        popularity: details.popularity,
        poster_path: details.poster_path,
        vote_average: details.vote_average,
        vote_count: details.vote_count
      )

      # Met à jour les genres associés
      details.genre_ids.each do |genre_id|
        genre = Genre.find_or_create_by!(id: genre_id)
        GenresTmdbTv.find_or_create_by!(tmdb_tv: tmdb_entry, genre: genre)
      end

      puts "Série ID #{entry_id} mise à jour avec succès."
    rescue Tmdb::Error => e
      puts "Erreur pour la série ID #{entry_id} : #{e.message}. Ignorée."
    rescue ActiveRecord::RecordInvalid => e
      puts "Erreur de validation pour la série ID #{entry_id} : #{e.message}. Ignorée."
    rescue StandardError => e
      puts "Erreur inattendue pour la série ID #{entry_id} : #{e.message}. Ignorée."
    end
  end

  # Recherche de toutes les séries sans ID TMDb
  def self.search_all_tmdb_id
    where(tmdb_id: nil).find_each do |ygg_tv|
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

  # Détection d’une saison complète
  def complete_season?
    return true if name.match?(/S\d{1,2}(\s|-|_)?COMPLETE/i)
    return true if name.match?(/Saison\s\d+\sComplète/i)
    return true if season_complete_based_on_tmdb?
    
    false
  end

  # Détection d’une série complète
  def complete_series?
    return true if name.match?(/COMPLETE SERIES/i)
    return true if name.match?(/Intégrale/i)
    return true if name.match?(/SERIE COMPLETE/i)
    return true if name.match?(/S\d+-S\d+/i)
    return true if series_complete_based_on_tmdb?

    false
  end
  private

  # Nom de la catégorie via la sous-catégorie
  def category_name
    sub_category&.category&.name
  end
end
