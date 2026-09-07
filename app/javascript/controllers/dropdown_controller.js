import { Controller } from "@hotwired/stimulus"

// Generic click-to-toggle dropdown (navbar user menu, notifications, etc.)
// that closes itself when clicking outside.
export default class extends Controller {
  static targets = ["panel"]

  connect() {
    this.boundHide = this.hideOnClickOutside.bind(this)
  }

  disconnect() {
    document.removeEventListener("click", this.boundHide)
  }

  toggle(event) {
    event.stopPropagation()
    const isOpen = this.panelTarget.classList.toggle("is-open")
    event.currentTarget.setAttribute("aria-expanded", isOpen)

    if (isOpen) {
      document.addEventListener("click", this.boundHide)
    } else {
      document.removeEventListener("click", this.boundHide)
    }
  }

  hideOnClickOutside(event) {
    if (!this.element.contains(event.target)) this.close()
  }

  close() {
    this.panelTarget.classList.remove("is-open")
    document.removeEventListener("click", this.boundHide)
  }
}
