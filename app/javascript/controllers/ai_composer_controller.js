import { Controller } from "@hotwired/stimulus"

// Handles the AI message composer: Ctrl+Enter submit and loading state.
export default class extends Controller {
  static targets = ["input", "submit"]

  connect() {
    this.inputTarget.addEventListener("keydown", this._onKeydown.bind(this))
  }

  disconnect() {
    this.inputTarget.removeEventListener("keydown", this._onKeydown.bind(this))
  }

  submit(event) {
    if (!this.inputTarget.value.trim()) {
      event.preventDefault()
      return
    }
    this.submitTarget.disabled = true
    this.submitTarget.value    = "Sending…"
    this.inputTarget.disabled  = true
  }

  _onKeydown(event) {
    if (event.key === "Enter" && (event.ctrlKey || event.metaKey)) {
      event.preventDefault()
      this.element.requestSubmit()
    }
  }
}
