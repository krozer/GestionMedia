class YggTv < ApplicationRecord
	require 'amatch'
  include NameCleaner # Inclusion du module
	# Relations
	belongs_to :sub_category, foreign_key: 'sub_category', primary_key: 'code', optional: true
	belongs_to :tmdb_tv, optional: true, class_name: 'TmdbTv'
	has_and_belongs_to_many :tags, join_table: :tags_ygg_tvs
  
  # Extraire les propriétés depuis le champ `name`
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
      self.titre = extract_title_from_name
      assign_tags_from_database
    end
  end

  def extract_title_from_name
    return nil unless name.present? # Vérifie que le nom est non-nil et non-vide
    
    cleaned_name = name.dup # Crée une copie du nom
  
    # Étape 1 : Trouver les limites du titre
    metadata_patterns = [
      /(19\d{2}|20\d{2})/,           # Année
      /S\d{1,2}/i,                   # Saison
      /E\d{1,2}/i,                   # Épisode
      /(1080p|720p|2160p|4K)/i,      # Résolution
      /(MULTI|TRUEFRENCH|FRENCH|VOSTFR|VOF|VFF|VF2|VFI|VF)/i, # Langue
      /(x264|x265|H264|H265|AV1|HEVC)/i, # Codec
      /(DTS|DDP|AC3|AAC|E-AC3)/i,    # Audio
      /(BluRay|WEB(-)?DL|HDTV|HDRip|WEBRip|BDRIP|NF.WEB|AMZN.WEB|HDLight|HDR|WEB)/i # Source
    ]
    
    # Trouver la première occurrence d'un motif à supprimer
    first_metadata_position = metadata_patterns.map { |pattern| cleaned_name =~ pattern }.compact.min
    
    cleaned_name = cleaned_name[0...first_metadata_position] if first_metadata_position
  
    # Étape 2 : Nettoyage des caractères spéciaux
    cleaned_name.gsub!(/[\[\]\(\)\-_.]/, ' ') # Remplace les caractères spéciaux par des espaces
    cleaned_name.squeeze!(' ')               # Réduit les espaces multiples
    cleaned_name.strip!                      # Supprime les espaces en début et fin
  
    cleaned_name
  end
  


  #      /(PROPER|REPACK|UNRATED|EXTENDED|DIRECTOR.S.CUT|iNTEGRALE|Intégrale|Custom|COMPLETE|iNTERNAL|10bits?)/i

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
    if sorted_results.size > 1 && sorted_results[0][:score] == sorted_results[1][:score]
      Rails.logger.info "Ex-aequo détecté pour '#{titre}'."
      return nil
    end
    best_match = sorted_results.first
    best_match && best_match[:score] > 0.5 ? best_match[:result] : nil
  end
end