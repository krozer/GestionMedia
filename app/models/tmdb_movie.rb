class TmdbMovie  < ApplicationRecord
	self.primary_key = 'id'

	has_many :yggs, foreign_key: 'tmdb_id'
	has_many :genres_tmdb_movies, class_name: 'GenresTmdbMovie', dependent: :destroy
	has_many :genres, through: :genres_tmdb_movies
	validates :id, presence: true, uniqueness: true
	validates :title, presence: true

  def self.update_tmdb_entry(movie_id)
    begin
      # Récupérer les détails du film
      movie_details = Tmdb::Movie.detail(movie_id, language: "fr")
  
      # Initialiser ou trouver l'enregistrement dans la base de données
      tmdb_entry = TmdbMovie.find_or_initialize_by(id: movie_id)
  
      # Mettre à jour les champs
      tmdb_entry.update!(
        title: movie_details.title,
        release_date: movie_details.release_date,
        overview: movie_details.overview,
        adult: movie_details.adult,
        backdrop_path: movie_details.backdrop_path,
        original_language: movie_details.original_language,
        original_title: movie_details.original_title,
        popularity: movie_details.popularity,
        poster_path: movie_details.poster_path,
        video: movie_details.video,
        vote_average: movie_details.vote_average,
        vote_count: movie_details.vote_count
      )
  
      match_result.genre_ids.each do |genre_id|
        genre = Genre.find_or_create_by!(id: genre_id)
        GenresTmdbMovie.find_or_create_by!(tmdb_movie: tmdb_movie, genre: genre)
      end
    
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
  
  
  
end
  