import { Controller } from "@hotwired/stimulus"

// Video player controller — same lifecycle pattern as audio_player_controller.
// Targets: video, playBtn, scrubber, currentTime, totalTime, volume, speed, fullscreenBtn
export default class extends Controller {
  static targets = [
    "video", "playBtn", "scrubber",
    "currentTime", "totalTime", "volume", "speed", "fullscreenBtn"
  ]

  // ── lifecycle ──────────────────────────────────────────────────────────────

  connect() {
    this._onMetadata   = this._handleMetadata.bind(this)
    this._onTimeUpdate = this._handleTimeUpdate.bind(this)
    this._onEnded      = this._handleEnded.bind(this)
    this._onPlay       = this._handlePlay.bind(this)
    this._onPause      = this._handlePause.bind(this)
    this._onFsChange   = this._handleFullscreenChange.bind(this)

    const v = this.videoTarget
    v.addEventListener("loadedmetadata", this._onMetadata)
    v.addEventListener("timeupdate",     this._onTimeUpdate)
    v.addEventListener("ended",          this._onEnded)
    v.addEventListener("play",           this._onPlay)
    v.addEventListener("pause",          this._onPause)
    document.addEventListener("fullscreenchange", this._onFsChange)

    if (v.readyState >= 1) this._handleMetadata()
  }

  disconnect() {
    const v = this.videoTarget
    v.removeEventListener("loadedmetadata", this._onMetadata)
    v.removeEventListener("timeupdate",     this._onTimeUpdate)
    v.removeEventListener("ended",          this._onEnded)
    v.removeEventListener("play",           this._onPlay)
    v.removeEventListener("pause",          this._onPause)
    document.removeEventListener("fullscreenchange", this._onFsChange)

    if (!v.paused) v.pause()
  }

  // ── actions ────────────────────────────────────────────────────────────────

  togglePlay() {
    const v = this.videoTarget
    if (v.paused) {
      v.play().catch(() => {})
    } else {
      v.pause()
    }
  }

  // Click anywhere on the video screen also toggles play/pause
  screenClick() {
    this.togglePlay()
  }

  seek() {
    const v = this.videoTarget
    if (v.duration) {
      v.currentTime = parseFloat(this.scrubberTarget.value)
    }
  }

  setVolume() {
    this.videoTarget.volume = parseFloat(this.volumeTarget.value)
  }

  setSpeed() {
    this.videoTarget.playbackRate = parseFloat(this.speedTarget.value)
  }

  toggleFullscreen() {
    if (document.fullscreenElement) {
      document.exitFullscreen()
    } else {
      // Request fullscreen on the whole player container so controls stay in view
      this.element.requestFullscreen().catch(() => {
        // Fallback: try the video element itself (some mobile browsers)
        this.videoTarget.requestFullscreen?.().catch(() => {})
      })
    }
  }

  // ── private event handlers ─────────────────────────────────────────────────

  _handleMetadata() {
    const dur = this.videoTarget.duration
    this.scrubberTarget.max = dur || 0
    this.totalTimeTarget.textContent = this._fmt(dur)
  }

  _handleTimeUpdate() {
    const v   = this.videoTarget
    const cur = v.currentTime
    const dur = v.duration || 0

    this.scrubberTarget.value = cur
    this.currentTimeTarget.textContent = this._fmt(cur)

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

  _handleFullscreenChange() {
    const isFs = !!document.fullscreenElement
    if (this.hasFullscreenBtnTarget) {
      this.fullscreenBtnTarget.setAttribute(
        "aria-label", isFs ? "Exit fullscreen" : "Fullscreen"
      )
    }
    this.element.classList.toggle("is-fullscreen", isFs)
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  _fmt(seconds) {
    if (!seconds || isNaN(seconds) || !isFinite(seconds)) return "–:––"
    const m = Math.floor(seconds / 60)
    const s = Math.floor(seconds % 60).toString().padStart(2, "0")
    return `${m}:${s}`
  }
}
