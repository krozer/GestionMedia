$env:RAILS_ENV = "production"
ruby .\bin\get_yggtorrent.rb animation 5
ruby .\bin\get_yggtorrent.rb film 5
rails runner "PlexMovie.full_sync"
rails runner "TmdbApi.sync_full"
rails runner "TmdbMovie.update_tmdb_entries"
rails runner "TmdbMovie.sync_trakt(Rails.application.credentials.dig(:trakt, :user))"
rails runner "YggMovie.search_all_tmdb_id"