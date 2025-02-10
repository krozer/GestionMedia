# app\services\html_parser.rb
require "nokogiri"

class HtmlParser
  def initialize(file_path,type)
    @file_path = file_path
    @media_type = type
  end

  def extract_data
    html = File.open(@file_path) { |f| Nokogiri::HTML(f) }

    # Trouver les lignes dans le <tbody> du tableau
    rows = html.xpath("//section[@id='#torrents']//table/tbody/tr")

    if rows.empty?
      puts "Aucune ligne trouvée dans le <tbody> de la section #torrents."
      return []
    end

    # Parcourir les lignes et extraire les données
    rows.map do |row|
      data = parse_row(row)
      save_to_db(data) if data
      data
    end.compact
  end

  private

  def parse_row(row)
    cells = row.css("td") # Sélectionner les cellules (<td>)

    # Ignorer les lignes qui n'ont pas assez de cellules
    return if cells.nil? || cells.empty?

    # Extraire les informations nécessaires
    data = {
      id: extract_id(cells[2]),
      name: extract_name(cells[1]),
      url: extract_url(cells[1]),
      sub_category: SubCategory.find_by(code: extract_type(cells[0])),
      size: extract_size(cells[5]),
      added_date: extract_date(cells[4]),
    }
  
    if data[:id].nil? || data[:name].nil? || data[:url].nil?
      puts "Erreur : Données incomplètes pour la ligne #{row.text.strip}."
      return nil
    end
  
    data
  end

  def save_to_db(data)
    required_keys = [:id, :name, :url, :sub_category, :size, :added_date]
    missing_keys = required_keys.select { |key| data[key].nil? }
    unless missing_keys.empty?
      puts "Erreur : Données manquantes : #{missing_keys.join(', ')}"
      return
    end
    ygg =
    case @media_type
    when "film" then YggMovie.find_or_initialize_by(id: data[:id])
    when "serie" then YggTv.find_or_initialize_by(id: data[:id])
    else
      raise ArgumentError, "Type inconnu : #{@media_type}"
    end
    
    ygg.assign_attributes(data)
    ygg.extract_properties_from_name # Enrichir avec les propriétés extraites
    if ygg.save
      puts "Donnée enregistrée : #{ygg.name}"
    else
      puts "Erreur lors de l'enregistrement : #{ygg.errors.full_messages.join(', ')}"
    end
  end

  def extract_id(cell)
    return nil if cell.nil? # Vérifie si la cellule est vide
    link = cell.css("a").first
    unless link
      puts "Erreur : lien manquant dans la cellule pour l'ID."
      return nil
    end
    link["target"] # Extrait l'identifiant de l'URL
  end

  def extract_name(cell)
    return nil if cell.nil? # Vérifie si la cellule est vide
    link = cell.css("a#torrent_name").first
    return nil unless link # Vérifie l'existence du lien
    link.text.strip
  end

  def extract_url(cell)
    return nil if cell.nil? # Vérifie si la cellule est vide
    link = cell.css("a#torrent_name").first
    return nil unless link # Vérifie l'existence du lien
    link["href"]
  end

  def extract_type(cell)
    return nil if cell.nil? # Vérifie si la cellule est vide
    hidden_div = cell.css("div.hidden").first
    unless hidden_div
      puts "Erreur : Type non trouvé dans la cellule."
      return nil
    end # Vérifie l'existence du div caché
    hidden_div.text.strip
  end

  def extract_date(cell)
    return nil if cell.nil? # Vérifie si la cellule est vide
    hidden_div = cell.css("div.hidden").first
    return nil unless hidden_div # Vérifie l'existence du div caché
    timestamp = hidden_div.text.strip.to_i # Convertir la chaîne en entier
    Time.at(timestamp).to_datetime # Convertir l'horodatage en objet Date
  end

  def extract_size(cell)
    return nil if cell.nil? # Vérifie si la cellule est vide
    size_text = cell.text.strip

    # Extraire la valeur numérique et l'unité
    if size_text =~ /([\d\.]+)([KMGT])o/i
      value = $1.to_f
      unit = $2.upcase

      # Convertir en octets selon l'unité
      multiplier = case unit
      when "K" then 1024
      when "M" then 1024**2
      when "G" then 1024**3
      when "T" then 1024**4
      else 1
      end
      (value * multiplier).round
    else
      puts "Format de taille inconnu : #{size_text}"
      nil # Retourne nil si le format ne correspond pas
    end
  end
end
