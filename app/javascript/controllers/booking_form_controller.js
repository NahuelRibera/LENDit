import { Controller } from "@hotwired/stimulus"

// Live rental-days/total-price preview as the borrower picks dates.
// Pure client-side arithmetic — the server independently recomputes and
// validates everything on submit, this is only a convenience preview.
export default class extends Controller {
  static targets = ["start", "end", "summary", "days", "total", "submit"]
  static values = { priceCents: Number }

  connect() {
    this.update()
  }

  startChanged() {
    if (this.startTarget.value) this.endTarget.min = this.startTarget.value
    this.update()
  }

  update() {
    const start = this.startTarget.value
    const end = this.endTarget.value

    if (!start || !end) return this.hideSummary()

    const days = Math.round((new Date(end) - new Date(start)) / 86400000) + 1
    if (days < 1) return this.hideSummary()

    const totalCents = days * this.priceCentsValue
    this.daysTarget.textContent = `${days} rental day${days === 1 ? "" : "s"}`
    this.totalTarget.textContent = `€${(totalCents / 100).toFixed(2)}`
    this.summaryTarget.hidden = false
    this.submitTarget.disabled = false
  }

  hideSummary() {
    this.summaryTarget.hidden = true
    this.submitTarget.disabled = true
  }
}
