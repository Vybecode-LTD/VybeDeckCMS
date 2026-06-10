import { Controller } from "@hotwired/stimulus"

// Controls the AI assistant layout: auto-scroll to bottom of messages.
export default class extends Controller {
  static targets = ["messages", "newInput", "newSubmit"]

  connect() {
    this._scrollToBottom()
  }

  newConversation() {
    window.location.href = this.element.dataset.newUrl || "/admin/ai"
  }

  submitNewConversation(event) {
    const input = this.hasNewInputTarget ? this.newInputTarget : null
    if (input && !input.value.trim()) {
      event.preventDefault()
      input.focus()
      return
    }
    if (this.hasNewSubmitTarget) this.newSubmitTarget.disabled = true
  }

  _scrollToBottom() {
    if (this.hasMessagesTarget) {
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
    }
  }
}
