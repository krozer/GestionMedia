class TmdbTv < ApplicationRecord
	self.primary_key = 'id'
  
	has_many :genres_tmdb_tvs, dependent: :destroy
	has_many :genres, through: :genres_tmdb_tvs
  
	validates :id, presence: true, uniqueness: true
	validates :name, presence: true
  
	# Méthode pour mettre à jour une série via l'API TMDb
	def self.update_tmdb_tv(tv_id)
	  begin
		tv_details = Tmdb::TV.detail(tv_id, language: 'fr')
		tmdb_tv = TmdbTv.find_or_initialize_by(id: tv_id)
  
		tmdb_tv.update!(
		  name: tv_details.name,
		  original_name: tv_details.original_name,
		  first_air_date: tv_details.first_air_date,
		  origin_country: tv_details.origin_country&.join(', '),
		  backdrop_path: tv_details.backdrop_path,
		  poster_path: tv_details.poster_path,
		  overview: tv_details.overview,
		  popularity: tv_details.popularity,
		  vote_average: tv_details.vote_average,
		  vote_count: tv_details.vote_count
		)
  
		# Mettre à jour les genres associés
		genres = tv_details.genres.map do |genre|
		  Genre.find_or_create_by!(id: genre.id) do |g|
			g.name = genre.name
		  end
		end
		tmdb_tv.genres = genres
  
		puts "Série ID #{tv_id} mise à jour avec succès."
	  rescue Tmdb::Error => e
		puts "Erreur TMDb pour la série ID #{tv_id} : #{e.message}"
	  rescue ActiveRecord::RecordInvalid => e
		puts "Erreur de validation pour la série ID #{tv_id} : #{e.message}"
	  rescue StandardError => e
		puts "Erreur inattendue pour la série ID #{tv_id} : #{e.message}"
	  end
	end
  
	# Méthode pour mettre à jour plusieurs séries récemment modifiées
	def self.update_tmdb_tvs
	  page = 1
  
	  loop do
		response = Tmdb::Change.tv(page: page)
		tvs = response.results
  
		break if tvs.blank?
  
		tvs.each do |tv|
		  update_tmdb_tv(tv.id)
		rescue Tmdb::Error => e
		  puts "Erreur TMDb pour la série ID #{tv.id} : #{e.message}"
		rescue StandardError => e
		  puts "Erreur inattendue pour la série ID #{tv.id} : #{e.message}"
		end
  
		page += 1
		break if page > response.total_pages
	  end
  
	  puts "Mise à jour des séries terminée."
	end
  end
  