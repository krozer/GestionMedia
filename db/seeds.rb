# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
# Charger les genres pour les films et les séries
def sync_genres
	Tmdb::Genre.movie_list.each do |genre_data|
	  Genre.find_or_create_by!(id: genre_data.id) do |genre|
		genre.name = genre_data.name
	  end
	end
  
	Tmdb::Genre.tv_list.each do |genre_data|
	  Genre.find_or_create_by!(id: genre_data.id) do |genre|
		genre.name = genre_data.name
	  end
	end
  
	puts "Genres synchronisés avec succès."
  end
  
  sync_genres