class Tag < ApplicationRecord
	has_and_belongs_to_many :ygg_movies, join_table: :tags_ygg_movies
	has_and_belongs_to_many :ygg_tvs, join_table: :tags_ygg_tvs
	validates :name, presence: true, uniqueness: true
	validates :pattern, presence: true
end
