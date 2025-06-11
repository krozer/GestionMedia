namespace :ygg_tv do
	desc "Recherche et met à jour les tmdb_id, détails, saisons et épisodes"
	task update_tmdb_data: :environment do
	  puts "Mise à jour des données TMDb pour YggTv..."
  
	  YggTv.where(tmdb_tv_id: nil).find_each do |ygg_tv|
		ygg_tv.search_tmdb
	  end
  
	  YggTv.where.not(tmdb_id: nil).find_each do |ygg_tv|
		ygg_tv.update_tmdb_details
	  end
  
	  puts "Mise à jour terminée ! ✅"
	end
  end
  