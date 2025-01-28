# lib\plex_api.rb
require 'httparty'

class PlexApi
  include HTTParty
  base_uri 'http://127.0.0.1:32400'

  def initialize(token = Rails.application.credentials.dig(:plex, :token))
    raise ArgumentError, "Token Plex manquant. Vérifiez vos credentials ou passez un token valide." unless token

    @headers = {
      "X-Plex-Token" => token
    }
  end

  def library_sections
    response = self.class.get('/library/sections', headers: @headers)
    parse_response(response)["MediaContainer"]["Directory"]
  end

  def library_files(section_id)
	response = self.class.get("/library/sections/#{section_id}/all", headers: @headers)
	data = parse_response(response)["MediaContainer"]
	data["Metadata"] || data["Video"] || data["Directory"]
  end
  
  def file_metadata(file_id)
	response = self.class.get("/library/metadata/#{file_id}", headers: @headers)
	# 1) Inspecter la réponse brute
	puts response.body
  
	data = parse_response(response)
	# 2) Inspecter après parsing
	puts data.inspect
  
	container = data["MediaContainer"]
	# 3) Selon le type de média, Plex peut renvoyer "Metadata" ou "Video"
	metadata = container["Metadata"] || container["Video"] || container["Directory"]
  
	metadata&.first
  end
  def extract_file_details(file)
    media = file["Media"].first
    part = media["Part"].first

    {
      title: file["title"],
      resolution: media["videoResolution"],
      video_codec: media["videoCodec"],
      audio_codec: media["audioCodec"],
      audio_language: media.dig("audioProfile"),
      file_path: part["file"],
      file_size: human_readable_size(part["size"]),
      is_french: detect_language(part, "fre"),
      is_multi: detect_multi_language(part),
      tmdb_id: extract_tmdb_id(file["guid"])
    }
  end

  # Nouvelle méthode pour extraire les fichiers d'une liste de sections
  def extract_from_sections(section_names)
    sections = library_sections.select { |s| section_names.include?(s["title"]) }
    raise "Sections non trouvées : #{section_names - sections.map { |s| s["title"] }}" if sections.empty?

    sections.each_with_object([]) do |section, results|
      puts "Traitement de la section : #{section['title']}"
      files = library_files(section["key"])
      files.each do |file|
        results << extract_file_details(file)
      end
    end
  end

  private

  def extract_tmdb_id(guid)
    return nil unless guid.include?('themoviedb')
    guid.match(/themoviedb:\/\/(\d+)\?/)&.captures&.first
  end

  def detect_language(part, lang_code)
    part["Streams"].any? { |stream| stream["streamType"] == 2 && stream["language"] == lang_code }
  end

  def detect_multi_language(part)
    languages = part["Streams"].select { |stream| stream["streamType"] == 2 }.map { |s| s["language"] }
    languages.uniq.size > 1
  end

  def human_readable_size(size)
    units = ['B', 'KB', 'MB', 'GB', 'TB']
    return "0 B" unless size

    exp = (Math.log(size) / Math.log(1024)).to_i
    exp = [exp, units.size - 1].min
    "%.2f %s" % [size.to_f / (1024 ** exp), units[exp]]
  end

  def parse_response(response)
    if response.success?
      response.parsed_response
    else
      raise "Erreur lors de la requête Plex : #{response.code} - #{response.message}"
    end
  end
  def self.normalize_to_array(data)
    data.is_a?(Array) ? data : [data].compact
  end
end
