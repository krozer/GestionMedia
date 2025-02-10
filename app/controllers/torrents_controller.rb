require "open-uri"

class TorrentsController < ApplicationController
  def download
    begin
      ygg_movie = YggMovie.find(params[:id])
      passkey = Rails.application.credentials.dig(:ygg, :passkey)
      torrent_url = "https://www.ygg.re/rss/download?id=#{ygg_movie.id}&passkey=#{passkey}"

      Rails.logger.info "Téléchargement du fichier torrent via Edge : #{torrent_url}"

      # Supprimer d'éventuels fichiers .torrent existants
      downloads_dir = "C:/Users/krozer/Downloads"
      Dir.glob("#{downloads_dir}/*.torrent").each { |file| File.delete(file) }

      # Lancer Edge pour forcer le téléchargement
    #   edge_command = "start microsoft-edge:\"#{torrent_url}\""
	  edge_command = "D:/app/gestionMedia/temporaire.exe \"#{torrent_url}\""
      system(edge_command)

      # Attendre que le fichier .torrent apparaisse
      torrent_file = nil
      10.times do
        sleep(1)
        torrent_files = Dir.glob("#{downloads_dir}/*.torrent")
        unless torrent_files.empty?
          torrent_file = torrent_files.first
          break
        end
        Rails.logger.info "En attente du fichier torrent..."
      end

      if torrent_file.nil?
        Rails.logger.error "Le fichier .torrent ne s'est pas téléchargé."
        render json: { success: false, error: "Échec du téléchargement via Edge" }, status: :unprocessable_entity
        return
      end

      Rails.logger.info "Fichier torrent détecté : #{torrent_file}"

      # Charger la config pour récupérer le répertoire de destination
      config_path = Rails.root.join("config", "ygg_urls.yml")
      config = YAML.load_file(config_path)
      movie_dir = config["download_directory"] || "C:\\Torrents"

      Rails.logger.info "Répertoire de téléchargement : #{movie_dir}"

      # Lancer qBittorrent avec le fichier téléchargé
      qbittorrent_path = '"C:\\Program Files\\qBittorrent\\qbittorrent.exe"'
      qb_command = "#{qbittorrent_path} --save-path=\"#{movie_dir}\" --skip-dialog=true \"#{torrent_file}\""

      Rails.logger.info "Exécution de la commande : #{qb_command}"
      system(qb_command)

      render json: { success: true }
    rescue StandardError => e
      Rails.logger.error "Erreur dans TorrentsController#download : #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: { success: false, error: e.message }, status: :unprocessable_entity
    end
  end
end
