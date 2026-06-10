import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel"]

  toggle() {
    this.panelTarget.style.display =
      this.panelTarget.style.display === "none" ? "flex" : "none"
  }

  // Close panel when clicking outside
  close(event) {
    if (!this.element.contains(event.target)) {
      this.panelTarget.style.display = "none"
    }
  }

  connect() {
    this._outsideClick = this.close.bind(this)
    document.addEventListener("click", this._outsideClick, true)
  }

  disconnect() {
    document.removeEventListener("click", this._outsideClick, true)
  }
}
