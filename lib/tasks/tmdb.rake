namespace :tmdb do
	desc "Mettre à jour les enregistrements TMDb"
	task update: :environment do
		TmdbMovie.update_tmdb_entries
	end
  end