class YggMoviesController < ApplicationController
  def index
    @search_query = params[:search].presence || ""
    @filter_params = params[:filter] || {}

    # Subquery pour trouver le premier YggMovie pour chaque tmdb_id
    subquery = YggMovie.select('tmdb_id, MIN(added_date) AS earliest_date').group(:tmdb_id)

    # Requête principale
    @ygg_movies = TmdbMovie
    .joins("INNER JOIN (#{subquery.to_sql}) subquery ON subquery.tmdb_id = tmdb_movies.id")
    .joins("INNER JOIN ygg_movies ON ygg_movies.tmdb_id = tmdb_movies.id AND ygg_movies.added_date = subquery.earliest_date")
    .includes(:genres) # Inclure les genres pour éviter les N+1
    .where('LOWER(tmdb_movies.title) LIKE ? OR LOWER(tmdb_movies.original_title) LIKE ?', "%#{@search_query.downcase}%", "%#{@search_query.downcase}%")
    .order(sort_column + ' ' + sort_direction)
    .distinct
    .page(params[:page])
    .per(33)

    # Appliquer les filtres
    @ygg_movies = apply_filters(@ygg_movies, @filter_params)

end
def movie_details
  @tmdb_movie = TmdbMovie.find(params[:id])
  @filter_params = params[:filter] || {}

  # Récupérer les YggMovies associés avec ou sans filtres
  base_scope = YggMovie.where(tmdb_id: params[:id])
  ygg_movies_scope = apply_filters_ygg(base_scope, @filter_params) || base_scope

  @ygg_movies = base_scope
  @filtered_ygg_movie_ids = ygg_movies_scope.any? ? ygg_movies_scope.pluck(:id) : nil

  respond_to do |format|
    format.html { render partial: "movie_details" }
  end
end

def associate_tmdb
  ygg_movie = YggMovie.find(params[:id])
  tmdb_id = params[:tmdb_id]

  begin
    ygg_movie.create_or_update_tmdb_entry(tmdb_id)
    render json: { message: "L'association a été mise à jour avec succès !" }, status: :ok
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
end
