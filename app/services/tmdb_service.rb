class TmdbService
	def self.search_movie(query)
	  Tmdb::Search.movie(query).results
	end
  
	def self.fetch_movie_details(tmdb_id)
	  Tmdb::Movie.detail(tmdb_id)
	end
  
	def self.fetch_movie_credits(tmdb_id)
	  Tmdb::Movie.credits(tmdb_id)
	end
  end
  