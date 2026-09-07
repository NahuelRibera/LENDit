import { Controller } from "@hotwired/stimulus"

// Toggles the mobile navigation drawer from the navbar's hamburger button.
export default class extends Controller {
  static targets = ["panel"]

  toggle(event) {
    const isOpen = this.panelTarget.classList.toggle("is-open")
    event.currentTarget.setAttribute("aria-expanded", isOpen)
  }

  close() {
    this.panelTarget.classList.remove("is-open")
  }
}
