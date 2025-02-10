import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["modal", "card","tmdbResults","correctionModal","searchInput"];

  connect() {
    console.log("MovieModalController connecté !");
  }

  openModal(event) {
    const card = event.currentTarget; // La carte cliquée
    const tmdbId = card.getAttribute("data-tmdb-id"); // Récupère l'ID TMDb
    console.log("Carte cliquée :", card);
    console.log("TMDB ID :", tmdbId);
  
    // Prépare l'URL pour récupérer le contenu dynamique
    const searchParams = new URLSearchParams(window.location.search);
    const fetchUrl = `/ygg_movies/${tmdbId}/details?${searchParams.toString()}`;
    console.log("URL de fetch avec filtres :", fetchUrl);
  
    // Récupère la modal et son contenu
    const modal = this.modalTarget;
    const modalContent = modal.querySelector(".modal-content");
  
    // Effectue la requête pour récupérer le contenu
    fetch(fetchUrl)
      .then((response) => {
        if (!response.ok) {
          throw new Error(`Erreur réseau : ${response.status}`);
        }
        return response.text();
      })
      .then((html) => {
        // console.log("HTML reçu :", html);
        modalContent.innerHTML = html; // Injecte le contenu dans la modal
        modal.classList.remove("hidden"); // Affiche la modal
      })
      .catch((error) => console.error("Erreur lors du fetch :", error));
  }

  closeModal() {
    // Cache la modal
    this.modalTarget.classList.add("hidden");
  }


searchTmdb(event) {
  const button = event.currentTarget;
  const yggId = button.getAttribute("data-ygg-id");
  const yggTitre = button.getAttribute("data-ygg-titre");
  const query = this.searchInputTarget.value.trim();
  let search=query
  if (!query) {
    search=yggTitre
  }
  if (!yggId) {
    console.error("ID YggMovie non trouvé sur le bouton.");
    return;
  }
  const searchButton = this.correctionModalTarget.querySelector(".search-button");
  searchButton.dataset.yggId = yggId;

  console.log("Recherche TMDb déclenchée pour YGGid ",yggId);
	event.preventDefault(); // Empêche le rechargement de la page


    // const query = this.searchInputTarget.value;
    console.log("Query :", yggTitre);

    if (search.trim() === "") {
      console.warn("La recherche est vide");
      return;
    }

    // Effectuer une requête à l'API TMDb pour rechercher les films
    fetch(`/tmdb_search?query=${encodeURIComponent(search)}`)
      .then((response) => response.json())
      .then((results) => {
        console.log("Résultats TMDb :", results);
        this.displayResults(yggId,results);
      })
      .catch((error) => {
        console.error("Erreur lors de la recherche TMDb :", error);
      });
  }

  displayResults(yggId,results) {
    const resultsContainer = this.tmdbResultsTarget;
    resultsContainer.innerHTML = ""; // Réinitialise les résultats précédents
    this.correctionModalTarget.classList.remove("hidden");
    if (results.length === 0) {
      resultsContainer.innerHTML = "<p>Aucun résultat trouvé.</p>";
      return;
    }

    results.forEach((result) => {
      const resultHtml = `
        <div class="tmdb-result" data-tmdb-id="${result.id}">
          <img src="https://image.tmdb.org/t/p/w200${result.poster_path}" alt="${result.title}">
          <h4>${result.title} (${new Date(result.release_date).getFullYear()})</h4>
          <button 
            class="select-button" 
            data-action="click->movie-modal#selectTmdb"
            data-ygg-id="${yggId}"
            data-tmdb-id="${result.id}"
          >
            Sélectionner
          </button>
        </div>
      `;
      resultsContainer.insertAdjacentHTML("beforeend", resultHtml);
    });
  }

  selectTmdb(event) {
    const button = event.currentTarget;
    const yggId = button.getAttribute("data-ygg-id");
    const tmdbId = button.getAttribute("data-tmdb-id");
    // const tmdbId = event.currentTarget.dataset.tmdbId;
    console.log("TMDb ID sélectionné :", tmdbId);

    fetch(`/ygg_movies/${yggId}/associate_tmdb`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector(
          'meta[name="csrf-token"]'
        ).content,
      },
      body: JSON.stringify({ tmdb_id: tmdbId }),
    })
      .then((response) => {
        if (response.ok) {
          console.log("YggMovie mis à jour avec TMDb ID :", tmdbId);
          this.closeModal(); // Ferme la modal après mise à jour
        } else {
          console.error("Erreur lors de la mise à jour du TMDb ID");
        }
      })
      .catch((error) => {
        console.error("Erreur réseau :", error);
      });
  }
  toggleWatchlist(event) {
    event.stopPropagation();
    const badge = event.currentTarget;
    const mediaId = badge.dataset.mediaId;
    const mediaType = badge.dataset.mediaType;
    const inWatchlist = badge.classList.contains("watchlist-active");
    
    // const endpoint = inWatchlist 
    //   ? `/tmdb/watchlist/remove` 
    //   : `/tmdb/watchlist/add`;
    const endpoint = 'watchlist/toggle'
    fetch(endpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').getAttribute("content"),
      },
      body: JSON.stringify({ media_id: mediaId, media_type: mediaType }),
    })
      .then((response) => {
        if (response.ok) {
          badge.classList.toggle("watchlist-active", !inWatchlist);
          console.log(`Watchlist mis à jour : ${!inWatchlist ? "Ajouté" : "Retiré"}`);
        } else {
          console.error("Échec de la mise à jour de la Watchlist");
        }
      })
      .catch((error) => {
        console.error("Erreur lors de la requête :", error);
      });
  }
  downloadTorrent(event) {
    event.preventDefault();

    const yggId = event.currentTarget.dataset.yggId;
    const yggName = event.currentTarget.dataset.yggName;

    fetch(`/download_torrent/${yggId}`, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content,
        "Content-Type": "application/json"
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        alert(`Téléchargement lancé : ${yggName}`);
      } else {
        alert(`Erreur: ${data.error}`);
      }
    })
    .catch(error => console.error("Erreur :", error));
  }
  selectTmdb(event) {
    const button = event.currentTarget;
    const yggId = button.getAttribute("data-ygg-id");
    const tmdbId = button.getAttribute("data-tmdb-id");
    
    console.log("Select Tmdb 2")

    fetch(`/ygg_movies/${yggId}/associate_tmdb`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
      },
      body: JSON.stringify({ tmdb_id: tmdbId }),
    })
      .then(response => response.json())
      .then(data => {
        if (data.error) {
          console.error("Erreur :", data.error);
          alert(data.error);
        } else {
          console.log("Succès :", data.message);
          alert(data.message);
          if (window.location.pathname === "/ygg_movies/next_unmatched") {
            window.location.href = "/ygg_movies/next_unmatched"; // Recharge la page proprement
          }
          // Charger le prochain film
          if (data.next_movie_id) {
            window.location.href = `/ygg_movies/${data.next_movie_id}/next_unmatched`;
          } else {
            alert("🎉 Tous les films ont un TMDb ID !");
            window.location.reload();
          }
        }
      })
      .catch(error => {
        console.error("Erreur réseau :", error);
      });
  }
  reloadPage(event) {
    event.preventDefault(); // Empêche la soumission par défaut
    const form = event.target;

    fetch(form.action + "?" + new URLSearchParams(new FormData(form)), {
      method: "GET",
      headers: {
        "X-Requested-With": "XMLHttpRequest"
      }
    })
    .then(response => response.text())
    .then(html => {
      document.documentElement.innerHTML = html; // Remplace tout le HTML
    })
    .catch(error => console.error("Erreur lors de la recherche :", error));
  }
}