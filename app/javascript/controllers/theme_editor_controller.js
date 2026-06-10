import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["lightPreview", "darkPreview", "colorInput", "textInput", "fontSelect", "fontUrlInput"]

  connect() {
    this.applyAll()
  }

  applyAll() {
    this.colorInputTargets.forEach(input => this.applyColor(input))
    if (this.hasFontSelectTarget) this.syncFont(this.fontSelectTarget)
  }

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
    if (!/^#[0-9a-fA-F]{6}$/.test(val)) return
    const key = textInput.dataset.tokenKey
    const colorInput = this.colorInputTargets.find(i => i.dataset.tokenKey === key)
    if (colorInput) {
      colorInput.value = val
      this.applyColor(colorInput)
    }
  }

  applyColor(input) {
    const cssVar = input.dataset.cssVar
    const mode   = input.dataset.mode
    if (!cssVar) return
    const target = mode === "dark" ? this.darkPreviewTarget : this.lightPreviewTarget
    target.style.setProperty(cssVar, input.value)
  }

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
    // Lazily load the font for the preview
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
