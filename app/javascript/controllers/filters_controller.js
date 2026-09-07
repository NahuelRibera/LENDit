import { Controller } from "@hotwired/stimulus"

// Toggles the mobile filter panel on the browse/search page.
export default class extends Controller {
  static targets = ["panel"]

  toggle() {
    this.panelTarget.classList.toggle("is-open")
  }
}
