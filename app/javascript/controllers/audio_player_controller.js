import { Controller } from "@hotwired/stimulus"

// Audio player controller
// Targets: audio, playBtn, scrubber, currentTime, totalTime, volume, speed
// Values: none (everything is driven by the <audio> element itself)
export default class extends Controller {
  static targets = [
    "audio", "playBtn", "scrubber",
    "currentTime", "totalTime", "volume", "speed"
  ]

  // ── lifecycle ──────────────────────────────────────────────────────────────

  connect() {
    // Store bound handlers so we can remove them in disconnect()
    this._onMetadata   = this._handleMetadata.bind(this)
    this._onTimeUpdate = this._handleTimeUpdate.bind(this)
    this._onEnded      = this._handleEnded.bind(this)
    this._onPlay       = this._handlePlay.bind(this)
    this._onPause      = this._handlePause.bind(this)

    const a = this.audioTarget
    a.addEventListener("loadedmetadata", this._onMetadata)
    a.addEventListener("timeupdate",     this._onTimeUpdate)
    a.addEventListener("ended",          this._onEnded)
    a.addEventListener("play",           this._onPlay)
    a.addEventListener("pause",          this._onPause)

    // If metadata was already loaded (e.g. cached), fire once
    if (a.readyState >= 1) this._handleMetadata()
  }

  disconnect() {
    const a = this.audioTarget
    a.removeEventListener("loadedmetadata", this._onMetadata)
    a.removeEventListener("timeupdate",     this._onTimeUpdate)
    a.removeEventListener("ended",          this._onEnded)
    a.removeEventListener("play",           this._onPlay)
    a.removeEventListener("pause",          this._onPause)

    // Ensure audio stops if the player is removed from DOM mid-play
    if (!a.paused) a.pause()
  }

  // ── actions ────────────────────────────────────────────────────────────────

  togglePlay() {
    const a = this.audioTarget
    if (a.paused) {
      a.play().catch(() => {}) // silently handle autoplay policy errors
    } else {
      a.pause()
    }
  }

  seek() {
    const a = this.audioTarget
    if (a.duration) {
      a.currentTime = parseFloat(this.scrubberTarget.value)
    }
  }

  setVolume() {
    this.audioTarget.volume = parseFloat(this.volumeTarget.value)
  }

  setSpeed() {
    this.audioTarget.playbackRate = parseFloat(this.speedTarget.value)
  }

  // ── private event handlers ─────────────────────────────────────────────────

  _handleMetadata() {
    const dur = this.audioTarget.duration
    this.scrubberTarget.max = dur || 0
    this.totalTimeTarget.textContent = this._fmt(dur)
  }

  _handleTimeUpdate() {
    const a   = this.audioTarget
    const cur = a.currentTime
    const dur = a.duration || 0

    this.scrubberTarget.value       = cur
    this.currentTimeTarget.textContent = this._fmt(cur)

    // Drive the CSS gradient that shows playback progress on the range track
    const pct = dur > 0 ? (cur / dur) * 100 : 0
    this.scrubberTarget.style.setProperty("--pct", `${pct.toFixed(2)}%`)
  }

  _handleEnded() {
    this.playBtnTarget.setAttribute("aria-label", "Play")
    this.playBtnTarget.setAttribute("aria-pressed", "false")
    this.playBtnTarget.classList.remove("is-playing")
  }

  _handlePlay() {
    this.playBtnTarget.setAttribute("aria-label", "Pause")
    this.playBtnTarget.setAttribute("aria-pressed", "true")
    this.playBtnTarget.classList.add("is-playing")
  }

  _handlePause() {
    this.playBtnTarget.setAttribute("aria-label", "Play")
    this.playBtnTarget.setAttribute("aria-pressed", "false")
    this.playBtnTarget.classList.remove("is-playing")
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  _fmt(seconds) {
    if (!seconds || isNaN(seconds) || !isFinite(seconds)) return "–:––"
    const m = Math.floor(seconds / 60)
    const s = Math.floor(seconds % 60).toString().padStart(2, "0")
    return `${m}:${s}`
  }
}
