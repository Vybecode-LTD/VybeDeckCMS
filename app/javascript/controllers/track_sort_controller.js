import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { reorderUrl: String }

  connect() {
    this._dragging = null
  }

  dragStart(event) {
    this._dragging = event.currentTarget
    event.currentTarget.classList.add("track-row--dragging")
    event.dataTransfer.effectAllowed = "move"
  }

  dragOver(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"
    const target = event.currentTarget
    if (target !== this._dragging) {
      const rect = target.getBoundingClientRect()
      const midY = rect.top + rect.height / 2
      if (event.clientY < midY) {
        target.parentNode.insertBefore(this._dragging, target)
      } else {
        target.parentNode.insertBefore(this._dragging, target.nextSibling)
      }
    }
  }

  drop(event) {
    event.preventDefault()
    this._saveOrder()
  }

  dragEnd(event) {
    event.currentTarget.classList.remove("track-row--dragging")
    this._dragging = null
  }

  _saveOrder() {
    const rows = this.element.querySelectorAll("[data-track-id]")
    const positions = Array.from(rows).map(r => r.dataset.trackId)

    // Update visible numbers
    rows.forEach((row, i) => {
      const numEl = row.querySelector(".track-row__number")
      if (numEl) numEl.textContent = i + 1
    })

    fetch(this.reorderUrlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ positions })
    })
  }
}
