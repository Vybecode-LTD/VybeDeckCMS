import { Controller } from "@hotwired/stimulus"

// Controls the cart sidebar drawer.
// Usage: wrap the entire drawer + overlay in
//   <div data-controller="cart">
// then add data-cart-target="panel" to the sliding panel and
//        data-cart-target="overlay" to the dimmed overlay.
// The cart button uses data-action="click->cart#open".
export default class extends Controller {
  static targets = ["panel", "overlay"]

  open() {
    this.panelTarget.classList.add("cart-panel--open")
    this.overlayTarget.classList.add("cart-overlay--visible")
    document.body.classList.add("cart-open")
    this.panelTarget.setAttribute("aria-hidden", "false")
    this.panelTarget.focus()
  }

  close() {
    this.panelTarget.classList.remove("cart-panel--open")
    this.overlayTarget.classList.remove("cart-overlay--visible")
    document.body.classList.remove("cart-open")
    this.panelTarget.setAttribute("aria-hidden", "true")
  }

  // Close on Escape key
  keydown(event) {
    if (event.key === "Escape") this.close()
  }
}
