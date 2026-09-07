import { Controller } from "@hotwired/stimulus"

// Classifies each message bubble as mine/theirs (can't be done server-side
// for a Turbo Stream broadcast, which renders once for every viewer) and
// keeps the thread scrolled to the latest message.
export default class extends Controller {
  static targets = ["messages", "message"]
  static values = { currentUserId: Number }

  connect() {
    this.scrollToBottom()
  }

  messageTargetConnected(element) {
    const isMine = Number(element.dataset.senderId) === this.currentUserIdValue
    element.classList.toggle("message-bubble--mine", isMine)
    this.scrollToBottom()
  }

  scrollToBottom() {
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }
}
