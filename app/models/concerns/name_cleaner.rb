module NameCleaner
	extend ActiveSupport::Concern
  
	included do
	  # Vous pouvez inclure ici des callbacks ou d'autres comportements si nécessaires
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
  end
  