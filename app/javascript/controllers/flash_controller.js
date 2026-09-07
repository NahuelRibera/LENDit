import { Controller } from "@hotwired/stimulus"

// Dismisses an individual flash/toast message.
export default class extends Controller {
  dismiss(event) {
    event.currentTarget.closest(".flash").remove()
  }
}
