class TmdbMovie  < ApplicationRecord
  include Watchlistable
	self.primary_key = 'id'

	has_many :ygg_movies, foreign_key: 'tmdb_id'
  has_many :plex_movies, foreign_key: :tmdb_id, primary_key: :tmdb_id
	has_many :genres_tmdb_movies, class_name: 'GenresTmdbMovie', dependent: :destroy
	has_many :genres, through: :genres_tmdb_movies
	validates :id, presence: true, uniqueness: true
	validates :title, presence: true

  def self.update_tmdb_entry(movie_id)
    begin
      # Récupérer les détails du film
      puts "Film ID #{movie_id} "
      movie_details = Tmdb::Movie.detail(movie_id, language: "fr")
      create_or_update_tmdb_entry(movie_details)
      
      puts "Film ID #{movie_id} mis à jour avec succès."
    rescue Tmdb::Error => e
      puts "Erreur pour le film ID #{movie_id} : #{e.message}. Ignoré."
    rescue ActiveRecord::RecordInvalid => e
      puts "Erreur de validation pour le film ID #{movie_id} : #{e.message}. Ignoré."
    rescue StandardError => e
      puts "Erreur inattendue pour le film ID #{movie_id} : #{e.message}. Ignoré."
    end
  end
  
  

  def self.update_tmdb_entries
    page = 1
  
    loop do
      response = Tmdb::Change.movie(page: page)
      movies = response.results
  
      break if movies.blank?
  
      # Récupérer uniquement les films déjà en base et qui n'ont pas été modifiés depuis 24 heures
      existing_movie_ids = TmdbMovie.where(id: movies.map(&:id))
                                    .where("updated_at < ?", 24.hours.ago)
                                    .pluck(:id)
  
      movies.each do |movie|
        next unless existing_movie_ids.include?(movie.id)
  
        begin
          update_tmdb_entry(movie.id)
        rescue Tmdb::Error => e
          puts "Erreur pour le film ID #{movie.id} : #{e.message}. Ignoré."
        rescue StandardError => e
          puts "Erreur inattendue pour le film ID #{movie.id} : #{e.message}. Ignoré."
        end
      end
  
      page += 1
      break if page > response.total_pages
    end
  
    puts "Mises à jour terminées pour les films existants dans la base et non modifiés depuis 24 heures."
  end
  
  def associate_tmdb
    ygg_movie = YggMovie.find(params[:id])
    tmdb_id = params[:tmdb_id]

    if ygg_movie.update(tmdb_id: tmdb_id)
      render json: { message: "L'association a été mise à jour avec succès !" }
    else
      render json: { message: "Erreur lors de la mise à jour de l'association." }, status: :unprocessable_entity
    end
  end
  
  def self.create_or_update_tmdb_entry(result)
    puts result
  
    # Accéder à `id` en tant que clé de hash
    tmdb_entry = TmdbMovie.find_or_initialize_by(id: result["id"])
    
    if tmdb_entry.new_record?
      tmdb_entry.update!(
        title: result["title"] || result["original_title"],
        release_date: result["release_date"],
        overview: result["overview"],
        adult: result["adult"],
        backdrop_path: result["backdrop_path"],
        original_language: result["original_language"],
        original_title: result["original_title"],
        popularity: result["popularity"],
        poster_path: result["poster_path"],
        video: result["video"],
        vote_average: result["vote_average"],
        vote_count: result["vote_count"]
      )
  
      # Mettre à jour les genres
      if result["genre_ids"].present?
        result["genre_ids"].each do |genre_id|
          genre = Genre.find_or_create_by!(id: genre_id)
          GenresTmdbMovie.find_or_create_by!(tmdb_movie: tmdb_entry, genre: genre)
        end
      end
  
      Rails.logger.info "Nouvelle entrée TMDb créée : #{result['title']} (TMDb ID: #{result['id']})"
    end
  
    tmdb_entry
  end
  
end
  