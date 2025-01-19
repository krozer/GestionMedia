class Genre < ApplicationRecord
	self.primary_key = 'id'
  
	# Associations avec TmdbMovie
	has_many :genres_tmdb_movies, class_name: 'GenresTmdbMovie', dependent: :destroy
	has_many :tmdb_movies, through: :genres_tmdb_movies
  
	# Associations avec TmdbTv
	has_many :genres_tmdb_tvs, class_name: 'GenresTmdbTv', dependent: :destroy
	has_many :tmdb_tvs, through: :genres_tmdb_tvs
  
	# Validations
	validates :id, presence: true, uniqueness: true
	validates :name, presence: true
  end
  