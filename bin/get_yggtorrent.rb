#!/usr/bin/env ruby
require_relative '../config/environment'
require 'open3'

# Vérification des arguments
if ARGV.length < 2
  puts "Usage: bin/get_yggtorrent.rb <nom> <nombre de pages> <page de debut>"
  exit 1
end

nom_recherche = ARGV[0]
nombre_pages = ARGV[1].to_i
page_depart = ARGV[2] ? ARGV[2].to_i : 1  # Par défaut, commence à la page 1


base_url = "https://www.ygg.re/"

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

# Récupération des URLs depuis le fichier de config
urls = Rails.configuration.urls["urls"]
url_entry = urls.find { |u| u["name"] == nom_recherche }

unless url_entry
  puts "Aucune URL trouvée pour '#{nom_recherche}'. Vérifiez le fichier config/ygg_urls.yml."
  exit 1
end

type = url_entry["type"] # "movie" ou "tv"

puts "Traitement de '#{nom_recherche}' (#{type}) sur #{nombre_pages} pages..."

nombre_pages.times do |i|
  page_offset = (page_depart + i - 1) * 50
  full_url = "#{base_url}engine/search?#{url_entry['suburl']}&page=#{page_offset}"
  puts "URL générée : #{full_url}"

  local_file_path = execute_temporaire("C:/Users/krozer/Downloads/Recherche - Yggtorrent.html", full_url)
  next unless local_file_path

  parser = HtmlParser.new(local_file_path, type)
  extracted_data = parser.extract_data

  extracted_data.each do |data|
    puts "Type détecté : #{type}"
    if type == "movie"
      puts "Traitement d'un film : #{data.inspect}"
    elsif type == "tv"
      puts "Traitement d'une série TV : #{data.inspect}"
    end
  end

  puts "--- Fin du traitement pour #{nom_recherche} (Page #{i + 1}) ---"
end
