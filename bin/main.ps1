$env:RAILS_ENV = "production"
Set-Location D:\app\ror\GestionMedia
ruby .\bin\get_yggtorrent.rb --type animation --max-pages 5
ruby .\bin\get_yggtorrent.rb --type film --max-pages 5
Exit-PSHostProcess
rails runner "PlexMovie.full_sync"
rails runner "TmdbApi.sync_full"
rails runner "TmdbMovie.update_tmdb_entries"
rails runner "TmdbMovie.sync_trakt(Rails.application.credentials.dig(:trakt, :user))"
rails runner "YggMovie.search_all_tmdb_id"