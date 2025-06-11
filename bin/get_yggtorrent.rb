#!/usr/bin/env ruby
require_relative '../config/environment'
require 'open3'
require 'optparse'
require 'uri'

# Fonction d'exécution du script temporaire
def execute_temporaire(file_path, url)
  command = "D:/app/gestionMedia/temporaire.exe \"#{url}\""
  puts "Exécution de : #{command}"
  stdout, stderr, status = Open3.capture3(command)
  
  if status.success?
    puts "Succès : #{stdout}"
    file_path
  else
    puts "Erreur : #{stderr}"
    nil
  end
end

# Initialisation des options avec valeurs par défaut
options = { debut: 0, max_pages: nil } 

OptionParser.new do |opts|
  opts.banner = "Usage: bin/get_yggtorrent.rb --type \"catégorie\" [--recherche \"mot clé\"] [--debut N] [--max-pages N]"

  opts.on("--type CATEGORIE", "Type/Catégorie de recherche (ex: films, séries, jeux) (Obligatoire sauf si --recherche)") do |t|
    options[:type] = t
  end

  opts.on("--recherche MOTS", "Terme de recherche (Optionnel, ajoute à name=&)") do |r|
    options[:recherche] = r
  end

  opts.on("--debut N", Integer, "Page de départ (Optionnel, par défaut: 1)") do |d|
    options[:debut] = d
  end

  opts.on("--max-pages N", Integer, "Nombre maximal de pages à récupérer (Optionnel, pour éviter une boucle infinie)") do |m|
    options[:max_pages] = m
  end
end.parse!

# Vérification des arguments obligatoires
if options[:type].nil? && options[:recherche].nil?
  puts "Erreur : Vous devez fournir au moins --type ou --recherche."
  exit 1
end

# Chargement de l'URL depuis la config
urls = Rails.configuration.urls["urls"]
url_entry = urls.find { |u| u["name"] == options[:type] }

unless url_entry
  puts "Aucune URL trouvée pour '#{options[:type]}'. Vérifiez config/ygg_urls.yml."
  exit 1
end

# Ajout de la recherche dans l'URL si demandée
if options[:recherche]
  recherche_encodee = URI.encode_www_form_component(options[:recherche])
  url_entry['suburl'].gsub!(/name=&/, "name=#{recherche_encodee}&")
end

type = url_entry["type"] # "movie" ou "tv"
base_url = "https://www.yggtorrent.top/"

puts "Traitement de '#{options[:type]}' (#{type}) depuis la page #{options[:debut]}..."

# Boucle tant qu'on trouve au moins 50 entrées
page_offset = options[:debut] * 50 # Transformation du numéro de page en offset réel
page_count = 0

loop do
  break if options[:max_pages] && page_count >= options[:max_pages]

  full_url = "#{base_url}engine/search?#{url_entry['suburl']}&page=#{page_offset}"
  puts "URL générée : #{full_url}"

  local_file_path = execute_temporaire("C:/Users/Seak_/Downloads/Recherche - Yggtorrent.html", full_url)
  break unless local_file_path

  parser = HtmlParser.new(local_file_path, type)
  extracted_data = parser.extract_data

  if extracted_data.empty?
    puts "Aucune entrée trouvée, arrêt du processus."
    break
  end

  extracted_data.each do |data|
    puts "Type détecté : #{type}"
    if type == "film"
      puts "Traitement d'un film : #{data.inspect}"
      YggMovie.find(data[:id]).search_tmdb
    elsif type == "tv"
      puts "Traitement d'une série TV : #{data.inspect}"
    end
  end

  puts "--- Fin du traitement pour #{options[:type]} (Offset #{page_offset}) ---"

  # Si on a moins de 50 entrées, on arrête la boucle
  break if extracted_data.size < 50

  # On passe à la page suivante en augmentant l'offset de 50
  page_offset += 50
  page_count += 1
end
