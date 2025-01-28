every 1.day, at: '4:00 am' do
	rake "tmdb:update"
end

every 1.day, at: '3:00 am' do
	runner "PlexMovie.full_sync"
	runner "TmdbApi.import_watchlist(media_type: 'movie')"
end
