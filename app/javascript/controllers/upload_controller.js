import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropzone", "input"]
  static values = { url: String }

  onDragOver(e) {
    e.preventDefault()
    this.dropzoneTarget.classList.add("is-dragging")
  }

  onDragLeave() {
    this.dropzoneTarget.classList.remove("is-dragging")
  }

  async onDrop(e) {
    e.preventDefault()
    this.dropzoneTarget.classList.remove("is-dragging")
    await this.sendFiles(Array.from(e.dataTransfer.files))
  }

  async onFileSelect(e) {
    await this.sendFiles(Array.from(e.target.files))
  }

  async sendFiles(files) {
    if (!files.length) return
    this.dropzoneTarget.classList.add("is-uploading")
    const token = document.querySelector("meta[name='csrf-token']")?.content ?? ""
    for (const file of files) {
      const body = new FormData()
      body.append("medium[file]", file)
      body.append("authenticity_token", token)
      await fetch(this.urlValue, { method: "POST", body })
    }
    window.location.reload()
  }
}
