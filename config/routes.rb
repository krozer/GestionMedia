Rails.application.routes.draw do
  get "tmdb_movies/search"
  # Routes pour YggMovies
  resources :ygg_movies, only: [:index] do
    collection do
      get :next_unmatched # Page pour traiter les films sans tmdb_id
    end
    member do
      get :details, action: :movie_details
      post :associate_tmdb
    end
  end
  post "/download_torrent/:id", to: "torrents#download", as: :download_torrent


  # Route pour la recherche TMDb
  get :tmdb_search, to: "tmdb_movies#search"
  
  post 'watchlist/toggle', to: 'watchlists#toggle'

  # Namespace Admin
  namespace :admin do
    resources :yggs, only: [:index, :edit, :update]
  end

  # Route santé pour vérifier l'état de l'application
  get "up" => "rails/health#show", as: :rails_health_check
end
