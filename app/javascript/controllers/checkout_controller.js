import { Controller } from "@hotwired/stimulus"

// Manages the embedded Stripe Payment Element checkout form.
//
// Flow:
// 1. User enters email and clicks "Pay Now".
// 2. Controller POSTs to /checkout to create an Order + PaymentIntent.
// 3. Stripe Elements mount in #stripe-payment-element with the client_secret.
// 4. stripe.confirmPayment() is called.  On success the browser is redirected
//    to /checkout/confirmation?payment_intent=<id>.
//
// Targets:
//   emailInput    — the email <input> element
//   paymentMount  — the <div> where the Stripe Element mounts
//   errorMessage  — an element for inline error text
//   payButton     — the "Pay Now" <button>
//
// Values:
//   confirmationUrl — path for the confirmation page (set in the view)
//   publishableKey  — Stripe publishable key (set in the view)
export default class extends Controller {
  static targets = ["emailInput", "paymentMount", "errorMessage", "payButton"]
  static values  = { confirmationUrl: String, publishableKey: String }

  connect() {
    this.stripe       = null
    this.elements     = null
    this.clientSecret = null
  }

  // Called by data-action="click->checkout#pay"
  async pay() {
    const email = this.emailInputTarget.value.trim()
    if (!email) {
      this.showError("Please enter your email address.")
      return
    }

    this.payButtonTarget.disabled    = true
    this.payButtonTarget.textContent = "Processing…"
    this.hideError()

    if (!this.clientSecret) {
      const ok = await this._fetchPaymentIntent(email)
      if (!ok) {
        this._resetButton()
        return
      }
    }

    await this._confirmPayment()
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  async _fetchPaymentIntent(email) {
    try {
      const res  = await fetch("/checkout", {
        method:  "POST",
        headers: {
          "Content-Type":  "application/json",
          "X-CSRF-Token":  document.querySelector("meta[name='csrf-token']")?.content ?? ""
        },
        body: JSON.stringify({ email })
      })
      const data = await res.json()

      if (!res.ok || data.error) {
        this.showError(data.error ?? "Could not start checkout. Please try again.")
        return false
      }

      this.clientSecret = data.clientSecret
      await this._mountPaymentElement()
      return true
    } catch {
      this.showError("Network error. Please check your connection and try again.")
      return false
    }
  }

  async _mountPaymentElement() {
    if (!window.Stripe) {
      this.showError("Payment system unavailable. Please refresh the page.")
      return
    }
    this.stripe   = Stripe(this.publishableKeyValue)
    this.elements = this.stripe.elements({ clientSecret: this.clientSecret })
    this.elements.create("payment").mount(this.paymentMountTarget)
  }

  async _confirmPayment() {
    if (!this.stripe || !this.elements) {
      this.showError("Payment element not ready. Please try again.")
      this._resetButton()
      return
    }

    const { error, paymentIntent } = await this.stripe.confirmPayment({
      elements:      this.elements,
      confirmParams: {
        return_url: `${window.location.origin}${this.confirmationUrlValue}`
      },
      redirect: "if_required"
    })

    if (error) {
      this.showError(error.message ?? "Payment failed. Please try again.")
      this._resetButton()
    } else if (paymentIntent?.status === "succeeded") {
      window.location.href = `${this.confirmationUrlValue}?payment_intent=${paymentIntent.id}`
    }
  }

  _resetButton() {
    this.payButtonTarget.disabled    = false
    this.payButtonTarget.textContent = "Pay Now"
  }

  showError(msg) {
    this.errorMessageTarget.textContent = msg
    this.errorMessageTarget.hidden      = false
  }

  hideError() {
    this.errorMessageTarget.textContent = ""
    this.errorMessageTarget.hidden      = true
  }
}
