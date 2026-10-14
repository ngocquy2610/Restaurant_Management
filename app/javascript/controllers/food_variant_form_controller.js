// Live price preview for the food variant form.
// Shows selected dish base price, recomputes base +/- adjustment = final,
// and warns when the final price would go below $0.
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["food", "adjustment", "base", "final", "hint", "warning"]
  static values = { prices: Object } // { "12": "9.99", ... }

  connect() {
    this.recompute()
  }

  recompute() {
    const id = this.hasFoodTarget ? this.foodTarget.value : ""
    const base = parseFloat(this.pricesValue[id] ?? "NaN")
    const hasBase = id !== "" && !Number.isNaN(base)

    if (this.hasBaseTarget) {
      this.baseTarget.textContent = hasBase ? `$${base.toFixed(2)}` : "—"
    }

    const raw = this.hasAdjustmentTarget ? this.adjustmentTarget.value : ""
    if (raw === "") {
      if (this.hasFinalTarget) this.finalTarget.textContent = hasBase ? `$${base.toFixed(2)}` : "—"
      if (this.hasHintTarget) this.hintTarget.textContent = hasBase ? "No adjustment yet — final equals base." : "Select a dish to preview pricing."
      this.toggleWarning(false, "")
      return
    }

    const adj = parseFloat(raw)
    if (Number.isNaN(adj)) {
      if (this.hasFinalTarget) this.finalTarget.textContent = "—"
      if (this.hasHintTarget) this.hintTarget.textContent = "Enter a number, e.g. 2.50 or -1.00."
      this.toggleWarning(false, "")
      return
    }

    if (!hasBase) {
      if (this.hasFinalTarget) this.finalTarget.textContent = adj >= 0 ? `+$${Math.abs(adj).toFixed(2)}` : `−$${Math.abs(adj).toFixed(2)}`
      if (this.hasHintTarget) this.hintTarget.textContent = "Select a dish to see the final price."
      this.toggleWarning(false, "")
      return
    }

    const final = base + adj
    if (this.hasFinalTarget) this.finalTarget.textContent = `$${final.toFixed(2)}`
    if (this.hasHintTarget) {
      const sign = adj < 0 ? "−" : "+"
      this.hintTarget.textContent = `$${base.toFixed(2)} ${adj < 0 ? "−" : "+"} $${Math.abs(adj).toFixed(2)} = $${final.toFixed(2)}${adj === 0 ? " (same as base)" : adj < 0 ? " (discount)" : " (surcharge)"}`
    }
    this.toggleWarning(final < 0, "Final price is below $0 — this variant cannot be saved.")
  }

  setAdjustment(event) {
    const value = event.currentTarget.dataset.value
    if (this.hasAdjustmentTarget && value !== undefined) {
      this.adjustmentTarget.value = value
      this.recompute()
    }
  }

  toggleWarning(show, message) {
    if (!this.hasWarningTarget) return
    this.warningTarget.textContent = message
    this.warningTarget.classList.toggle("hidden", !show)
  }
}
