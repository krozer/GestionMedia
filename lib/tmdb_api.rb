require 'net/http'
require 'json'

class TmdbApi
  API_BASE_URL = "https://api.themoviedb.org/3"

  # Méthode pour créer un session_id
  def self.create_session(request_token)
    url = URI("#{API_BASE_URL}/authentication/session/new?api_key=#{Rails.application.credentials.dig(:tmdb, :api_key)}")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(url)
    # request['Authorization'] = "Bearer #{Rails.application.credentials.dig(:tmdb, :bearer_token)}"
    request['Content-Type'] = 'application/json'

    # Récupérer le request_token (doit être validé via l'interface TMDb par l'utilisateur)
    # request_token = fetch_request_token

    body = { request_token: request_token }
    request.body = body.to_json

    response = http.request(request)

    if response.code == '200'
      JSON.parse(response.body)['session_id']
    else
      Rails.logger.error "Erreur lors de la création de la session : #{response.code} - #{response.message}"
      nil
    end
  end

  # Méthode pour récupérer un request_token
  def self.fetch_request_token
    url = URI("#{API_BASE_URL}/authentication/token/new?api_key=#{Rails.application.credentials.dig(:tmdb, :api_key)}")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(url)
    # request['Authorization'] = "Bearer #{Rails.application.credentials.dig(:tmdb, :bearer_token)}"
    request['Accept'] = 'application/json'

    response = http.request(request)

    if response.code == '200'
      request_token=JSON.parse(response.body)['request_token']
      "https://www.themoviedb.org/authenticate/#{request_token}"
    else
      Rails.logger.error "Erreur lors de la récupération du request_token : #{response.code} - #{response.message}"
      nil
    end
  end

  # Méthodes pour gérer la watchlist (ajout du session_id)
  def self.fetch_watchlist(media_type:, page:, session_id: Rails.application.credentials.dig(:tmdb, :session_id))
    raise ArgumentError, "media_type must be 'movies' or 'tv'" unless %w[movies tv].include?(media_type)
    url = URI("#{API_BASE_URL}/account/#{Rails.application.credentials.dig(:tmdb, :user_id)}/watchlist/#{media_type}?page=#{page}&language=fr-FR&sort_by=created_at.asc&session_id=#{session_id}")

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

  def self.add_to_watchlist(media_type:, media_id:, session_id: Rails.application.credentials.dig(:tmdb, :session_id))
    
    raise ArgumentError, "media_type must be 'movie' or 'tv'" unless %w[movie tv].include?(media_type)

    url = URI("#{API_BASE_URL}/account/#{Rails.application.credentials.dig(:tmdb, :user_id)}/watchlist?session_id=#{session_id}")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    
    request = Net::HTTP::Post.new(url)
    request["accept"] = 'application/json'
    request["content-type"] = 'application/json'
    request['Authorization'] = "Bearer #{Rails.application.credentials.dig(:tmdb, :bearer_token)}"

    body = {
      media_type: media_type,
      media_id: media_id,
      watchlist: true
    }

    request.body = body.to_json
    
    response = http.request(request)
       
    case response.code
    when '200'
      response.read_body
    else
      Rails.logger.error "Erreur API TMDb : #{response.code} - #{response.message}"
    end
  end

  def self.remove_from_watchlist(media_type:, media_id:, session_id: Rails.application.credentials.dig(:tmdb, :session_id))
    
    raise ArgumentError, "media_type must be 'movie' or 'tv'" unless %w[movie tv].include?(media_type)

    url = URI("#{API_BASE_URL}/account/#{Rails.application.credentials.dig(:tmdb, :user_id)}/watchlist?session_id=#{session_id}")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    
    request = Net::HTTP::Post.new(url)
    request["accept"] = 'application/json'
    request["content-type"] = 'application/json'
    request['Authorization'] = "Bearer #{Rails.application.credentials.dig(:tmdb, :bearer_token)}"

    body = {
      media_type: media_type,
      media_id: media_id,
      watchlist: false
    }

    request.body = body.to_json
    
    response = http.request(request)
       
    case response.code
    when '200'
      response.read_body
    else
      Rails.logger.error "Erreur API TMDb : #{response.code} - #{response.message}"
    end
  end

  # Méthode d'importation mise à jour
  def self.import_watchlist(media_type:, session_id: Rails.application.credentials.dig(:tmdb, :session_id))
    raise ArgumentError, "media_type must be 'movies' or 'tv'" unless %w[movies tv].include?(media_type)
    page = 1
    total_pages = 1

    reset_watchlist_flags(media_type: media_type)

    while page <= total_pages
      response = fetch_watchlist(media_type: media_type, page: page, session_id: session_id)

      if response.present?
        total_pages = response['total_pages']
        items = response['results']

        items.each do |item|
          if media_type == 'movies'
            TmdbMovie.create_or_update_tmdb_entry(item).tap do |entry|
              entry.watchlist = true
              entry.save
            end
          elsif media_type == 'tv'
            TmdbTv.create_or_update_tmdb_entry(item).tap do |entry|
              entry.watchlist = true
              entry.save
            end
          end
        end
      end

      page += 1
    end
  end

  def self.reset_watchlist_flags(media_type:)
    model = media_type == 'movie' ? TmdbMovie : TmdbTv
    model.update_all(watchlist: false)
  end

  def self.sync_full
    reset_watchlist_flags(media_type: 'movie')
    import_watchlist(media_type: 'movies')
  end
end
