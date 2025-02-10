class TmdbMovie  < ApplicationRecord
  include Watchlistable
	self.primary_key = 'id'

	has_many :ygg_movies, foreign_key: 'tmdb_id'
  has_many :plex_movies, foreign_key: :tmdb_id, primary_key: :id
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

  # Récupérer la date la plus récente de vu
  def self.derniere_date_vue
    maximum(:vu)
  end

  # Récupérer le dernier film vu
  def self.dernier_film_vu
    where.not(vu: nil).order(vu: :desc).first
  end

  def self.sync_trakt(username,full_sync=false)
    # Initialiser l'API Trakt
    trakt_api = TraktApi.new()

    # Récupérer la dernière date de visionnage enregistrée
    derniere_vu = full_sync ? nil : self.maximum(:vu)
    Rails.logger.info "Dernière date de visionnage en base : #{derniere_vu || 'Aucune'}"

    page = 1
    limit = 10 # Nombre d'éléments par page
    nouveaux_watched = []
    should_stop = false # Drapeau pour arrêter la boucle `loop`

    # Boucle sur l'API Trakt tant que les films récupérés sont plus récents que `derniere_vu`
    loop do
      response = trakt_api.watched(username, 'movies', page: page, limit: limit)
      data = response[:data]

      break if data.blank? # Arrêter si on reçoit une réponse vide (fin des données)

      data.each do |entry|
        watched_at = entry["watched_at"]&.to_datetime
        tmdb_id = entry.dig("movie", "ids", "tmdb")

        # Vérification que les données sont valides
        next if tmdb_id.nil? || watched_at.nil?

        # Si l'entrée est plus ancienne que `derniere_vu`, on met `should_stop = true`
        if derniere_vu && watched_at <= derniere_vu
          Rails.logger.info "Arrêt de la synchronisation : les entrées restantes sont plus anciennes que #{derniere_vu}."
          should_stop = true
          break # Quitte uniquement `each`, mais pas `loop`
        end

        nouveaux_watched << { tmdb_id: tmdb_id, watched_at: watched_at }
      end

      break if should_stop # Quitte `loop` après avoir terminé `each`
      
      page += 1 # Passer à la page suivante
    end

    Rails.logger.info "Nombre de nouveaux films regardés à synchroniser : #{nouveaux_watched.count}"

    # Appliquer la mise à jour des films en base
    nouveaux_watched.each do |entry|
      tmdb_id = entry[:tmdb_id]
      watched_at = entry[:watched_at]

      tmdb_movie = self.find_by(id: tmdb_id)

      if tmdb_movie
        Rails.logger.info "Mise à jour du film ID #{tmdb_id} avec la date #{watched_at}"
        tmdb_movie.update!(vu: watched_at)
      else
        Rails.logger.info "Film ID #{tmdb_id} non trouvé en base, tentative de création..."
        begin
          new_tmdb_movie = self.update_tmdb_entry(tmdb_id)
          
          if new_tmdb_movie
            Rails.logger.info "Film ID #{tmdb_id} créé avec succès, mise à jour de la date de visionnage."
            new_tmdb_movie.update!(vu: watched_at)
          else
            Rails.logger.warn "Impossible de récupérer les données TMDb pour ID #{tmdb_id}."
          end
        rescue StandardError => e
          Rails.logger.error "Erreur lors de la création du film TMDb ID #{tmdb_id} : #{e.message}"
        end
      end
    end

    Rails.logger.info "Synchronisation Trakt terminée."
  end
end
  