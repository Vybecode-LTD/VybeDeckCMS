import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages", "form", "input", "editForm", "editFormEl", "editInput",
                    "composer", "channelForm", "filename"]

  connect() {
    this.scrollToBottom()
  }

  scrollToBottom() {
    if (this.hasMessagesTarget) {
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
    }
  }

  // Called when a Turbo Stream appends a new message — scroll after DOM update
  messagesTargetConnected() {
    this.scrollToBottom()
  }

  handleKeydown(event) {
    // Ctrl+Enter or Cmd+Enter submits; plain Enter adds a newline (textarea default)
    if (event.key === "Enter" && (event.ctrlKey || event.metaKey)) {
      event.preventDefault()
      this.formTarget.requestSubmit()
    }
  }

  sendMessage(event) {
    event.preventDefault()
    const form = this.formTarget
    const input = this.inputTarget

    if (!input.value.trim() && !form.querySelector('[type="file"]')?.files?.length) return

    fetch(form.action, {
      method: "POST",
      body: new FormData(form),
      headers: { "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content }
    }).then(r => {
      if (r.ok) {
        input.value = ""
        if (this.hasFilenameTarget) this.filenameTarget.textContent = ""
        const fileInput = form.querySelector('[type="file"]')
        if (fileInput) fileInput.value = ""
      }
    })
  }

  editMessage(event) {
    const btn    = event.currentTarget
    const id     = btn.dataset.messageId
    const body   = btn.dataset.messageBody
    const url    = btn.closest(".chat-message").querySelector("[id^='chat-message-']")?.id

    this.editFormTarget.style.display = "block"
    this.composerTarget.querySelector(".chat-composer__form").style.display = "none"

    this.editInputTarget.value = body
    this.editFormElTarget.action =
      this.editFormElTarget.action.replace(/\/messages\/\d+/, `/messages/${id}`)
  }

  cancelEdit() {
    this.editFormTarget.style.display = "none"
    this.composerTarget.querySelector(".chat-composer__form").style.display = ""
  }

  toggleChannelForm() {
    const form = this.channelFormTarget
    form.style.display = form.style.display === "none" ? "block" : "none"
  }

  showFilename(event) {
    if (this.hasFilenameTarget && event.target.files[0]) {
      this.filenameTarget.textContent = event.target.files[0].name
    }
  }
}
