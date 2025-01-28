# app/models/concerns/name_properties.rb
module NameProperties
  extend ActiveSupport::Concern
  include NameCleaner # Inclusion du module si nécessaire

  included do
    # Vous pouvez inclure ici des callbacks ou d'autres comportements si nécessaires
  end
	class_methods do
		# Extraire les propriétés du nom
		def extract_properties_from_name(name)
			# 0) Isoler le nom de fichier si "name" est un chemin
			# On sépare par les slash/backslash et on prend la dernière partie
			name = name.split(/[\\\/]+/).last

			# 1) Extractions directes par regex
			annee      = name[/[^\d](19\d{2}|20\d{2})(?=[^\d])/, 1]&.to_i
			saison     = name[/S(?<saison>\d{1,2})(?=\.|\s|E|$)/i, :saison]&.to_i
			episode    = name[/E(?<episode>\d{1,2})(?=\.|\s|$)/i, :episode]&.to_i
			resolution = name[/(1080p|720p|2160p|4K)/i, 1]

			# 2) Gestion de la langue avec priorité à VFF
			keywords = %w[VFF MULTI TRUEFRENCH VOSTFR VOF VF2 VFI FRENCH VF]
			matches  = name.scan(/(#{keywords.join('|')})/i).flatten
			# Trouve le premier mot-clé dans l’ordre de la liste `keywords`
			langue   = keywords.find { |keyword| matches.map(&:upcase).include?(keyword.upcase) }
			langue   = langue&.upcase

			# 3) Autres attributs
			codec  = name[/(x264|x265|H264|H265|AV1|HEVC)/i, 1]&.upcase
			audio  = name[/(DTS|DDP|AC3|AAC|E-AC3)/i, 1]&.upcase
			canaux = name[/(5\.1|7\.1|2\.0)/, 1]
			source = name[/(BluRay|WEB(-)?DL|HDTV|HDRip|WEBRip|BDRIP|NF.WEB|AMZN.WEB|HDLight|HDR|WEB)/i, 1]&.upcase

			# 4) Titre principal
			titre = self.extract_title_from_name(name)

			# 5) Associer des tags (optionnel)
			tags = assign_tags_from_database(name)

			# Retourne éventuellement un hash, pour usage interne ou stockage
			{
        name:       name,
				annee:      annee,
				saison:     saison,
				episode:    episode,
				resolution: resolution,
				langue:     langue,
				codec:      codec,
				audio:      audio,
				canaux:     canaux,
				source:     source,
				titre:      titre,
				tags:       tags.map(&:name) # Retourne une liste des noms des tags
			}
		end
		# Extrait le titre principal en supprimant les métadonnées
    def extract_title_from_name(name)
      # Supprime toutes les métadonnées définies dans les regex
      metadata_patterns = [
        /(19\d{2}|20\d{2})/,                   # Année
        /S\d{1,2}/i, /E\d{1,2}/i,              # Saison / Épisode
        /(1080p|720p|2160p|4K)/i,              # Résolution
        /(MULTI|TRUEFRENCH|FRENCH|VOSTFR|VOF|VFF|VF2|VFI|VF)/i, # Langue
        /(x264|x265|H264|H265|AV1|HEVC)/i,     # Codec
        /(DTS|DDP|AC3|AAC|E-AC3)/i,            # Audio
        /(BluRay|WEB(-)?DL|HDTV|HDRip|WEBRip|BDRIP|NF.WEB|AMZN.WEB|HDLight|HDR|WEB)/i, # Source
        /(PROPER|REPACK|UNRATED|EXTENDED|DIRECTOR.S.CUT|iNTEGRALE|Intégrale|Custom|COMPLETE|iNTERNAL|10bits?)/i # Tags spéciaux
      ]
    
      # Supprime les métadonnées
      cleaned_name = name.dup
      metadata_patterns.each { |pattern| cleaned_name.gsub!(pattern, '') }
    
      # Nettoie les caractères spéciaux et espaces
      cleaned_name = clean_name(cleaned_name)
    
      # Retirer d’éventuels doublons de mots
      words = cleaned_name.split
      cleaned_name = words.uniq.join(' ')
    
      # Supprime les espaces superflus
      cleaned_name.strip
    end
		# Nettoie un nom pour supprimer les caractères spéciaux, espaces multiples, et espaces en début/fin
		def clean_name(name)
			return nil unless name.present?
		
			cleaned_name = name.dup
			cleaned_name.gsub!(/[\[\]\(\)\-_.:?!+,;"'’\/\\|©®™*<>~^%$#&€£¥]/, ' ') # Remplacer les caractères spéciaux par des espaces
			cleaned_name.squeeze!(' ') # Réduire les espaces multiples
			cleaned_name.strip! # Supprimer les espaces en début et fin
		
			cleaned_name
		end
		# Associer des tags (si vous avez un modèle Tag et un attribut name)
		def assign_tags_from_database(name)
			tag_patterns = Tag.all.index_by(&:name)
			matching_tags = tag_patterns.values.select do |tag|
				name.match?(Regexp.new(tag.pattern, Regexp::IGNORECASE))
			end
			matching_tags
		end

	end

  

end
