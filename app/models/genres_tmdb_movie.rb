class GenresTmdbMovie < ApplicationRecord
	belongs_to :tmdb_movie
	belongs_to :genre
  end