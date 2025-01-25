class WatchlistsController < ApplicationController
 def toggle
    media_id = params[:media_id]
    media_type = params[:media_type]

    if media_type == 'movie'
      model = TmdbMovie
      api_path_add = "movie"
    elsif media_type == 'tv'
      model = TmdbTv
      api_path_add = "tv"
    else
      render json: { error: 'Invalid media type' }, status: :unprocessable_entity and return
    end
    item = model.find(media_id)
    if item.watchlist?
      # Remove from watchlist
      success = TmdbApi.remove_from_watchlist(media_type: api_path_add, media_id: media_id)
      item.remove_from_watchlist if success
    else
      # Add to watchlist
      success = TmdbApi.add_to_watchlist(media_type: api_path_add, media_id: media_id)
      item.add_to_watchlist if success
    end

    if success
      render json: { in_watchlist: item.watchlist }
    else
      render json: { error: 'Failed to update watchlist on TMDb' }, status: :unprocessable_entity
    end
  end
end