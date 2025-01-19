import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="accordion"
export default class extends Controller {
  static targets = ["content", "header"];

  connect() {
    this.contentTarget.classList.remove("open"); // S'assurer qu'il est fermé par défaut
  }

  toggle() {
    this.contentTarget.classList.toggle("open");
  }
}
