import { Controller } from "@hotwired/stimulus"

// Focal-point picker for album artwork.
// Click anywhere on the image to set the (x%, y%) focal point used for
// object-position on the public album page.
export default class extends Controller {
  static targets = ["image", "dot", "xInput", "yInput"]

  pick(event) {
    const rect = this.imageTarget.getBoundingClientRect()
    const x = Math.round(Math.max(0, Math.min(100, ((event.clientX - rect.left) / rect.width)  * 100)))
    const y = Math.round(Math.max(0, Math.min(100, ((event.clientY - rect.top)  / rect.height) * 100)))

    this.xInputTarget.value = x
    this.yInputTarget.value = y

    this.dotTarget.style.left = `${x}%`
    this.dotTarget.style.top  = `${y}%`

    this.imageTarget.style.objectPosition = `${x}% ${y}%`
  }
}
