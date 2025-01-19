require_relative '../config/environment'

# Chemins nécessaires
autoit_script_path = "D:/app/gestionMedia/temporaire.exe"
download_path = "C:/Users/krozer/Downloads"

# URL de test
test_url = "https://www.ygg.re/engine/search?name=one+piece&description=&file=&uploader=&category=2145&sub_category=2179&option_langue%3Amultiple%5B%5D=2&option_langue%3Amultiple%5B%5D=4&do=search"

begin
  runner = AutoItRunner.new(autoit_script_path, download_path)
  html_file = runner.run(test_url)

  puts "Fichier généré : #{html_file}"
rescue => e
  puts "Erreur : #{e.message}"
end
