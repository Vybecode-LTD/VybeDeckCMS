import { Controller } from "@hotwired/stimulus"

// Embed Picker — adds an "Embed" button to every Trix toolbar in this element.
// When clicked, shows a URL input. On submit, calls the server preview endpoint
// and renders the iframe below the editor so the admin can see what the embed
// looks like before saving.
//
// Values:
//   preview-url  – the server endpoint URL (set via data-embed-picker-preview-url-value)
//
// Usage on any form wrapping a trix-editor:
//   <div data-controller="embed-picker"
//        data-embed-picker-preview-url-value="<%= admin_embed_preview_path %>">
//     <%= f.rich_text_area :body %>
//   </div>
export default class extends Controller {
  static values = { previewUrl: String }

  // ── lifecycle ────────────────────────────────────────────────────────────────

  connect() {
    this._onTrixInit = this._handleTrixInit.bind(this)
    this.element.addEventListener("trix-initialize", this._onTrixInit)
  }

  disconnect() {
    this.element.removeEventListener("trix-initialize", this._onTrixInit)
  }

  // ── private ───────────────────────────────────────────────────────────────────

  _handleTrixInit(event) {
    const trixEditor = event.target
    const toolbar    = trixEditor.toolbarElement
    if (!toolbar) return

    // Inject an "Embed" button into the file-tools group (or any group as fallback)
    const group = toolbar.querySelector(".trix-button-group--file-tools")
                  ?? toolbar.querySelector(".trix-button-group")
    if (!group) return

    const btn  = document.createElement("button")
    btn.type   = "button"
    btn.textContent = "⊞ Embed"
    btn.className   = "trix-button trix-button--embed"
    btn.title       = "Insert embed (YouTube, Vimeo, Spotify, SoundCloud, Apple Music)"
    btn.setAttribute("tabindex", "-1")
    btn.addEventListener("click", (e) => {
      e.preventDefault()
      this._showPicker(trixEditor)
    })
    group.appendChild(btn)
  }

  _showPicker(trixEditor) {
    // Find or create the picker panel below this editor
    const editorContainer = trixEditor.closest(".trix-container, [data-action*='embed-picker']")
                            ?? trixEditor.parentElement
    const existingPanel = editorContainer.querySelector(".embed-picker-panel")
    if (existingPanel) {
      existingPanel.querySelector("input[type='url']")?.focus()
      return
    }

    const panel = this._buildPanel((url) => this._loadPreview(url, panel))
    editorContainer.insertAdjacentElement("afterend", panel)
    panel.querySelector("input[type='url']")?.focus()
  }

  _buildPanel(onSubmit) {
    const panel = document.createElement("div")
    panel.className = "embed-picker-panel"
    panel.innerHTML = `
      <div class="embed-picker-panel__inner">
        <input class="embed-picker-panel__input" type="url"
               placeholder="Paste a YouTube, Vimeo, Spotify, SoundCloud, or Apple Music URL…"
               autocomplete="off">
        <button class="embed-picker-panel__submit button button--sm" type="button">Preview</button>
        <button class="embed-picker-panel__close button button--secondary button--sm" type="button" aria-label="Close">✕</button>
      </div>
      <div class="embed-picker-panel__preview"></div>
    `

    const input  = panel.querySelector("input")
    const submit = panel.querySelector(".embed-picker-panel__submit")
    const close  = panel.querySelector(".embed-picker-panel__close")

    const doSubmit = () => { if (input.value.trim()) onSubmit(input.value.trim()) }

    input.addEventListener("keydown", (e) => { if (e.key === "Enter") { e.preventDefault(); doSubmit() } })
    submit.addEventListener("click", doSubmit)
    close.addEventListener("click", () => panel.remove())

    return panel
  }

  async _loadPreview(url, panel) {
    const previewEl = panel.querySelector(".embed-picker-panel__preview")
    previewEl.innerHTML = '<p class="embed-picker-panel__loading">Loading preview…</p>'

    try {
      const endpoint = `${this.previewUrlValue}?url=${encodeURIComponent(url)}`
      const response = await fetch(endpoint, {
        headers: { "Accept": "text/html", "X-Requested-With": "XMLHttpRequest" }
      })

      if (response.ok) {
        const html = await response.text()
        previewEl.innerHTML = html
        previewEl.insertAdjacentHTML("beforeend",
          `<p class="embed-picker-panel__hint">
             This embed will be visible when you add the URL to an embed field on the page.
           </p>`)
      } else {
        previewEl.innerHTML =
          `<p class="embed-picker-panel__error">
             Could not recognise that URL. Try a YouTube, Vimeo, Spotify, SoundCloud, or Apple Music link.
           </p>`
      }
    } catch {
      previewEl.innerHTML =
        '<p class="embed-picker-panel__error">Preview failed — check your connection.</p>'
    }
  }
}
