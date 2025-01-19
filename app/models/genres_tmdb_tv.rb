class GenresTmdbTv < ApplicationRecord
	belongs_to :tmdb_tv, class_name: 'TmdbTv'
	belongs_to :genre
  end
  