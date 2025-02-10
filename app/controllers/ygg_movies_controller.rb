# app\controllers\ygg_movies_controller.rb
class YggMoviesController < ApplicationController
  def index
    @search_query = params[:search].presence || ""
    @filter_params = params[:filter] || {}
    @filter_watchlist = params[:filter_watchlist] == "1"

    # Subquery pour trouver le premier YggMovie pour chaque tmdb_id
    subquery = YggMovie.select('tmdb_id, MIN(added_date) AS earliest_date').group(:tmdb_id)

    # Requête principale
    @ygg_movies = TmdbMovie
    .joins("INNER JOIN (#{subquery.to_sql}) subquery ON subquery.tmdb_id = tmdb_movies.id")
    .joins("INNER JOIN ygg_movies ON ygg_movies.tmdb_id = tmdb_movies.id AND ygg_movies.added_date = subquery.earliest_date")
    .left_joins(:plex_movies) # ✅ Utilise `.left_joins` pour être compatible avec `.includes`
    .includes(:genres, :plex_movies) # ✅ Précharge pour éviter les requêtes N+1
    .where('LOWER(tmdb_movies.title) LIKE ? OR LOWER(tmdb_movies.original_title) LIKE ?', "%#{@search_query.downcase}%", "%#{@search_query.downcase}%")
    # .where.not(plex_movies: { tmdb_id: nil })
    .where.not("LOWER(ygg_movies.name) LIKE ?", '%.vfq.%') # 🔴 Exclure les noms contenant ".vfq."
    .order("#{sort_column} #{sort_direction}")
    .includes(:plex_movies)
    .distinct
    .page(params[:page])
    .per(33)

# 🟢 Correction du filtre "Films vus"
if params.dig(:filter, :tmdb_vu) == "1"   # Vu
  @ygg_movies = @ygg_movies.where.not(vu: nil)
elsif params.dig(:filter, :tmdb_vu) == "0" # Non vu
  @ygg_movies = @ygg_movies.where(vu: nil)
end

# 🟢 Correction du filtre "Présence dans Plex"
if params.dig(:filter, :plex_present) == "1"   # Présent dans Plex
  @ygg_movies = @ygg_movies.where.not(plex_movies: { tmdb_id: nil })
elsif params.dig(:filter, :plex_present) == "0" # Absent de Plex
  @ygg_movies = @ygg_movies.where(plex_movies: { tmdb_id: nil })
end

# 🟢 Correction du filtre "Watchlist TMDb"
if params.dig(:filter, :tmdb_watchlist) == "1"   # Dans la watchlist
  @ygg_movies = @ygg_movies.where(watchlist: true)
elsif params.dig(:filter, :tmdb_watchlist) == "0" # Pas dans la watchlist
  @ygg_movies = @ygg_movies.where(watchlist: false)
end

  # # Filtrage par watchlist
  # if params[:filter_watchlist] == "1"
  #   @ygg_movies = @ygg_movies.where(tmdb_id: TmdbMovie.where(watchlist: true).pluck(:id))
  # end

  #   # Appliquer les filtres
  #   @ygg_movies = apply_filters(@ygg_movies, @filter_params)

end
def movie_details
  @tmdb_movie = TmdbMovie.find(params[:id])
  @filter_params = params[:filter] || {}

  # Récupérer les YggMovies associés avec ou sans filtres
  base_scope = YggMovie.where(tmdb_id: params[:id])
  ygg_movies_scope = apply_filters_ygg(base_scope, @filter_params) || base_scope

  @ygg_movies = base_scope
  @filtered_ygg_movie_ids = ygg_movies_scope.any? ? ygg_movies_scope.pluck(:id) : nil
  @plex_movies = PlexMovie.where(tmdb_id: @tmdb_movie.id)

  respond_to do |format|
    format.html { render partial: "movie_details" }
  end
end
def next_unmatched
  @ygg_movie = YggMovie.where(tmdb_id: nil).order(:created_at).first
  @tmdb_results = []

  if params[:search].present?
    @tmdb_results = Tmdb::Search.movie(params[:search]).results
  elsif @ygg_movie
    @tmdb_results = Tmdb::Search.movie(@ygg_movie.titre).results
  end
  puts "Résultats TMDb envoyés à la vue : #{@tmdb_results.inspect}"
  respond_to do |format|
    format.html
    format.json { render json: { ygg_movie: @ygg_movie, tmdb_results: @tmdb_results } }
  end
end
def associate_tmdb
  ygg_movie = YggMovie.find(params[:id])
  tmdb_id = params[:tmdb_id]
  
  existing_entry = TmdbMovie.find_by(id: tmdb_id) || TmdbMovie.update_tmdb_entry(tmdb_id)
  puts "#{ygg_movie.inspect} :: #{params[:tmdb_id]} :: #{existing_entry.inspect}"
  begin
    ygg_movie.update!(tmdb_id: existing_entry.id)
    if request.referer&.include?("/ygg_movies/next_unmatched")
      redirect_to next_unmatched_ygg_movies_path, notice: "TMDb ID associé avec succès !"
    else
      next_movie = YggMovie.where(tmdb_id: nil).order(:created_at).first

          render json: {
        message: "TMDb ID associé avec succès !",
        next_movie_id: next_movie&.id,
        next_movie_title: next_movie&.titre
      }, status: :ok
    end
  rescue StandardError => e
    render json: { error: "Erreur : #{e.message}" }, status: :unprocessable_entity
  end
end
private

  def sort_column
    %w[tmdb_movies.title tmdb_movies.release_date tmdb_movies.popularity tmdb_movies.vote_average ygg_movies.added_date].include?(params[:sort]) ? params[:sort] : 'ygg_movies.added_date'
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : 'desc'
  end

  def apply_filters(scope, filters)
      # Filtres liés à YggMovie
      if filters[:source].present?
        scope = scope.where(ygg_movies: { source: filters[:source] })
      end
      if filters[:resolution].present?
        scope = scope.where(ygg_movies: { resolution: filters[:resolution] })
      end
      if filters[:langue].present?
        scope = scope.where(ygg_movies: { langue: filters[:langue] })
      end
    
      # Filtres liés à TmdbMovie
      if filters[:genres].present?
        scope = scope.joins(:genres).where(genres: { id: filters[:genres] })
      end
      if filters[:tmdb_langue].present?
        scope = scope.where(tmdb_movies: { original_language: filters[:tmdb_langue] })
      end
      if filters[:min_popularity].present?
        scope = scope.where('tmdb_movies.popularity >= ?', filters[:min_popularity].to_f)
      end
      if filters[:min_vote].present?
        scope = scope.where('tmdb_movies.vote_average >= ?', filters[:min_vote].to_f)
      end
    
      scope
    end
  def apply_filters_ygg(scope, filters)
    # Filtres liés à YggMovie
    if filters[:source].present?
      scope = scope.where(ygg_movies: { source: filters[:source] })
    end
    if filters[:resolution].present?
      scope = scope.where(ygg_movies: { resolution: filters[:resolution] })
    end
    if filters[:langue].present?
      scope = scope.where(ygg_movies: { langue: filters[:langue] })
    end
  end
  private

  def sort_column
    %w[
      tmdb_movies.release_date 
      tmdb_movies.title 
      ygg_movies.created_at 
      ygg_movies.updated_at 
      plex_movies.created_at
    ].include?(params[:sort]) ? params[:sort] : 'ygg_movies.created_at'
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : 'desc'
  end
end
