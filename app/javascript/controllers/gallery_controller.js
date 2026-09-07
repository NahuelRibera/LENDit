import { Controller } from "@hotwired/stimulus"

// Swaps the main listing image when a thumbnail is clicked.
export default class extends Controller {
  static targets = ["main", "thumb"]

  select(event) {
    this.mainTarget.src = event.currentTarget.dataset.fullUrl
    this.thumbTargets.forEach((thumb) => thumb.classList.remove("is-active"))
    event.currentTarget.classList.add("is-active")
  }
}
