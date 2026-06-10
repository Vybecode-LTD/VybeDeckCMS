import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "lightPreview", "darkPreview",
    "colorInput", "textInput",
    "rangeInput", "rangeTextInput",
    "fontSelect", "fontUrlInput"
  ]

  connect() {
    this.applyAll()
  }

  applyAll() {
    this.colorInputTargets.forEach(input => this.applyColor(input))
    this.rangeInputTargets.forEach(input => this.applyRange(input))
    if (this.hasFontSelectTarget) this.syncFont(this.fontSelectTarget)
  }

  // ── Colour picker ↔ text input ──────────────────────────────────────────

  tokenChanged(event) {
    const colorInput = event.target
    const key = colorInput.dataset.tokenKey
    const textInput = this.textInputTargets.find(i => i.dataset.tokenKey === key)
    if (textInput) textInput.value = colorInput.value
    this.applyColor(colorInput)
  }

  textChanged(event) {
    const textInput = event.target
    const val = textInput.value.trim()
    if (val !== "" && !/^#[0-9a-fA-F]{6}$/.test(val)) return
    const key = textInput.dataset.tokenKey
    const colorInput = this.colorInputTargets.find(i => i.dataset.tokenKey === key)
    if (colorInput && val.match(/^#[0-9a-fA-F]{6}$/)) {
      colorInput.value = val
      this.applyColor(colorInput)
    }
  }

  applyColor(input) {
    const cssVar = input.dataset.cssVar
    const mode   = input.dataset.mode
    if (!cssVar) return
    if (mode === "both") {
      this.lightPreviewTarget.style.setProperty(cssVar, input.value)
      this.darkPreviewTarget.style.setProperty(cssVar, input.value)
    } else {
      const target = mode === "dark" ? this.darkPreviewTarget : this.lightPreviewTarget
      target.style.setProperty(cssVar, input.value)
    }
  }

  // ── Range slider ↔ text input ───────────────────────────────────────────

  rangeChanged(event) {
    const range = event.target
    const key   = range.dataset.tokenKey
    const px    = `${range.value}px`
    const textInput = this.rangeTextInputTargets.find(i => i.dataset.tokenKey === key)
    if (textInput) textInput.value = px
    this.applyRange(range)
  }

  rangeTextChanged(event) {
    const textInput = event.target
    const val = textInput.value.trim()
    const numeric = parseInt(val, 10)
    if (isNaN(numeric)) return
    const key = textInput.dataset.tokenKey
    const range = this.rangeInputTargets.find(i => i.dataset.tokenKey === key)
    if (range) {
      range.value = numeric
      this.applyRange(range)
    }
  }

  applyRange(range) {
    const cssVar = range.dataset.cssVar
    if (!cssVar) return
    const px = `${range.value}px`
    this.lightPreviewTarget.style.setProperty(cssVar, px)
    this.darkPreviewTarget.style.setProperty(cssVar, px)
  }

  // ── Font ────────────────────────────────────────────────────────────────

  fontChanged(event) {
    this.syncFont(event.target)
  }

  syncFont(select) {
    const opt    = select.options[select.selectedIndex]
    const family = opt.value
    const url    = opt.dataset.fontUrl || ""
    if (this.hasFontUrlInputTarget) {
      this.fontUrlInputTarget.value = url
    }
    const fontFamily = `'${family}', sans-serif`
    this.lightPreviewTarget.style.fontFamily = fontFamily
    this.darkPreviewTarget.style.fontFamily  = fontFamily
    let link = document.getElementById("theme-preview-font")
    if (!link) {
      link = document.createElement("link")
      link.id  = "theme-preview-font"
      link.rel = "stylesheet"
      document.head.appendChild(link)
    }
    if (url) link.href = url
  }
}
