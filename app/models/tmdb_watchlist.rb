require 'net/http'
require 'json'

class TmdbWatchlist < ApplicationRecord
  validates :tmdb_id, uniqueness: true

  API_BASE_URL = "https://api.themoviedb.org/4"

  # Récupérer la watchlist (films ou séries)
  def self.fetch_watchlist(media_type: 'movie', page: 1)
    url = URI("#{API_BASE_URL}/account/#{Rails.application.credentials.dig(:tmdb, :account_id)}/#{media_type}/watchlist?page=#{page}&language=fr-FR")
    puts "#{url}"
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(url)
    request['Authorization'] = "Bearer #{Rails.application.credentials.dig(:tmdb, :bearer_token)}"
    request['Accept'] = 'application/json'

    response = http.request(request)

    if response.code == '200'
      JSON.parse(response.body)
    else
      Rails.logger.error "Erreur API TMDb : #{response.code} - #{response.message}"
      nil
    end
  end

  # Importer la watchlist
  def self.import_watchlist(media_type: 'movies')
    page = 1
    total_pages = 1

    while page <= total_pages
      response = fetch_watchlist(media_type: media_type, page: page)

      if response.present?
        total_pages = response['total_pages']
        items = response['results']

        items.each do |item|
          puts "#{item}"
          TmdbWatchlist.find_or_create_by(tmdb_id: item['id']) do |entry|
            entry.media_type = media_type
            entry.title = item['title'] || item['name']
            entry.release_date = item['release_date'] || item['first_air_date']
            entry.overview = item['overview']
            entry.poster_path = item['poster_path']
          end
        end
      end

      page += 1
    end
  end
end
