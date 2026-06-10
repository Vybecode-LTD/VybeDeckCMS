import { Controller } from "@hotwired/stimulus"

// Constrains HTML5 audio playback to a preview window [start, end] seconds.
export default class extends Controller {
  connect() {
    this.start = parseFloat(this.element.dataset.start || 0)
    this.end   = parseFloat(this.element.dataset.end   || 30)

    this.element.currentTime = this.start

    this._onPlay      = this._seekToStart.bind(this)
    this._onTimeUpdate = this._enforceEnd.bind(this)

    this.element.addEventListener("play",       this._onPlay)
    this.element.addEventListener("timeupdate", this._onTimeUpdate)
  }

  disconnect() {
    this.element.removeEventListener("play",       this._onPlay)
    this.element.removeEventListener("timeupdate", this._onTimeUpdate)
  }

  _seekToStart() {
    if (this.element.currentTime < this.start) {
      this.element.currentTime = this.start
    }
  }

  _enforceEnd() {
    if (this.element.currentTime >= this.end) {
      this.element.pause()
      this.element.currentTime = this.start
    }
  }
}
