Rails.application.routes.draw do
  get "tmdb_movies/search"
  # Routes pour YggMovies
  resources :ygg_movies, only: [:index] do
    member do
      get :details, action: :movie_details
      post :associate_tmdb
    end
  end

  # Route pour la recherche TMDb
  get :tmdb_search, to: "tmdb_movies#search"

  # Namespace Admin
  namespace :admin do
    resources :yggs, only: [:index, :edit, :update]
  end

  # Route santé pour vérifier l'état de l'application
  get "up" => "rails/health#show", as: :rails_health_check
end
