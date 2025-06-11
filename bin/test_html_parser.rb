require_relative '../config/environment'
# Exemple d'utilisation
require 'open3'

base_url = "https://www.yggtorrent.top/"

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

# Rails.configuration.urls["urls"].each do |url_entry|
#   20.times do |i| # Boucle sur 3 pages (0, 50, 100)
#     page_offset = i * 50
#     full_url = "#{base_url}engine/search?#{url_entry['suburl']}&page=#{page_offset}"
#     puts "URL générée : #{full_url}"

#     local_file_path = execute_temporaire("C:/Users/krozer/Downloads/Recherche - Yggtorrent.html", full_url)
#     next unless local_file_path

#     parser = HtmlParser.new(local_file_path)
#     extracted_data = parser.extract_data

#     extracted_data.each do |data|
#       puts data.inspect
#     end
#     puts "--- Fin du traitement pour #{url_entry["type"]} ---"
#   end
# end

Rails.configuration.urls["urls"].each do |url_entry|
  type = url_entry["type"] # "movie" ou "tv"

  1.times do |i| # Boucle sur 20 pages
    page_offset = i * 50
    full_url = "#{base_url}engine/search?#{url_entry['suburl']}&page=#{page_offset}"
    puts "URL générée : #{full_url}"

    local_file_path = execute_temporaire("C:/Users/krozer/Downloads/Recherche - Yggtorrent.html", full_url)
    next unless local_file_path

    parser = HtmlParser.new(local_file_path,type)
    extracted_data = parser.extract_data

    extracted_data.each do |data|
      puts "Type détecté : #{type}"
      if type == "movie"
        # Traiter les films
        puts "Traitement d'un film : #{data.inspect}"
      elsif type == "tv"
        # Traiter les séries TV
        puts "Traitement d'une série TV : #{data.inspect}"
      end
    end
    puts "--- Fin du traitement pour #{url_entry["type"]} ---"
  end
end
