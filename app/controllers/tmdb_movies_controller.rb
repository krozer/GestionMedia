class TmdbMoviesController < ApplicationController
  def search
    query = params[:query].to_s.strip

    if query.blank?
      render json: { error: 'La recherche est vide.' }, status: :unprocessable_entity
      return
    end

    begin
      # Utilisation de la gem TMDb pour effectuer la recherche
      search = Tmdb::Search.movie(query)
      results = search.results.map do |result|
        {
          id: result.id,
          title: result.title,
          original_title: result.original_title,
          release_date: result.release_date,
          poster_path: result.poster_path,
          popularity: result.popularity,
          vote_average: result.vote_average,
          overview: result.overview
        }
      end

      render json: results, status: :ok
    rescue StandardError => e
      render json: { error: "Erreur lors de la recherche : #{e.message}" }, status: :internal_server_error
    end
  end
end
