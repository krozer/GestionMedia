import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "correctionModal",
    "yggTitle",
    "tmdbResults",
    "searchInput",
  ];

  connect() {
    console.log("Movie Modal + Correction Controller connecté");
    this.setupEventListeners();
    this.modal = document.getElementById("correction-modal");
    // this.searchResults = document.getElementById("search-results");
    this.yggTitleElement = document.getElementById("ygg-title");
    // this.currentYggId = null;
  }

  setupEventListeners() {
    const movieCards = document.querySelectorAll(".movie-card");
    const modal = document.querySelector("#movie-modal");

    if (!modal) {
      console.error("Modal element not found");
      return;
    }

    const modalContent = modal.querySelector(".modal-content");
    const closeButton = modal.querySelector(".close-button");

    if (!modalContent || !closeButton) {
      console.error("Modal sub-elements not found");
      return;
    }

    movieCards.forEach((card) => {
      card.addEventListener("click", () => {
        console.log("Carte cliquée :", card);
        const tmdbId = card.getAttribute("data-tmdb-id");
        console.log("TMDB ID :", tmdbId);

        // Récupérer les paramètres des filtres actuels
        const searchParams = new URLSearchParams(window.location.search);

        // Ajouter les filtres actuels à l'URL de la requête
        const fetchUrl = `/ygg_movies/${tmdbId}/details?${searchParams.toString()}`;
        console.log("URL de fetch avec filtres :", fetchUrl);

        fetch(fetchUrl)
          .then((response) => response.text())
          .then((html) => {
            console.log("HTML reçu :", html);
            modalContent.innerHTML = html; // Insère le contenu dans le modal
            console.log("Contenu après injection :", modalContent.innerHTML);
            modal.classList.remove("hidden"); // Rend le modal visible
            console.log("Classe 'hidden' supprimée :", modal.classList);
          })
          .catch((error) => console.error("Erreur lors du fetch :", error));
      });
    });

    closeButton.addEventListener("click", () => {
      modal.classList.add("hidden");
    });

    window.addEventListener("click", (event) => {
      if (event.target === modal) {
        modal.classList.add("hidden");
      }
    });
  }

  openModal(event) {
	const yggId = event.currentTarget.dataset.yggId;
	const titre = event.currentTarget.dataset.titre;
  
	if (!yggId || !titre) {
		
	  console.error("Attributs manquants dans le bouton 'Corriger'.");
	  return;
	}
	this.modal.dataset.currentYggId = yggId;
	console.log("Recherche TMDb pour YggMovie ID :", this.modal.dataset.currentYggId);
	this.yggTitleElement.textContent = titre;
	this.modal.classList.remove("hidden");
  }

  closeModal() {
    this.modal.classList.add("hidden");
    this.tmdbResultsTarget.innerHTML = "";
  }

  searchTmdb(event) {
	if (!this.modal.dataset.currentYggId) {
		console.error("ID YggMovie non défini avant la sélection.");
		return;
	}
    console.log("Recherche TMDb déclenchée pour YGGid ",this.modal.dataset.currentYggId);
	event.preventDefault(); // Empêche le rechargement de la page


    const query = this.searchInputTarget.value;
    console.log("Query :", query);

    if (query.trim() === "") {
      console.warn("La recherche est vide");
      return;
    }

    // Effectuer une requête à l'API TMDb pour rechercher les films
    fetch(`/tmdb_search?query=${encodeURIComponent(query)}`)
      .then((response) => response.json())
      .then((results) => {
        console.log("Résultats TMDb :", results);
        this.displayResults(results);
      })
      .catch((error) => {
        console.error("Erreur lors de la recherche TMDb :", error);
      });
  }

  displayResults(results) {
    const resultsContainer = this.tmdbResultsTarget;
    resultsContainer.innerHTML = ""; // Réinitialise les résultats précédents

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
    const tmdbId = event.currentTarget.dataset.tmdbId;
    console.log("TMDb ID sélectionné :", tmdbId);

    fetch(`/ygg_movies/${this.modal.dataset.currentYggId}/associate_tmdb`, {
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
}
