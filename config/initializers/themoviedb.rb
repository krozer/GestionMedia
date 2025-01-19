Tmdb::Api.key(Rails.application.credentials.dig(:tmdb, :api_key) || ENV['TMDB_API_KEY'])
