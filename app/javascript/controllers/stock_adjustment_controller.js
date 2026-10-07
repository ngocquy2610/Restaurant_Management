import { Controller } from "@hotwired/stimulus"

// Drives the stock adjustment form: shows the selected ingredient's system
// quantity and previews the difference against the physical count before the
// user confirms.
export default class extends Controller {
  static targets = ["select", "system", "physical", "difference", "submit"]
  static values = { quantities: Object } // { "12": "9.99", ... }

  connect() {
    this.recompute()
  }

  recompute() {
    const id = this.selectTarget.value
    const system = parseFloat(this.quantitiesValue[id] ?? "0")
    const physicalRaw = this.physicalTarget.value

    this.systemTarget.textContent = id ? String(system) : "—"

    if (physicalRaw === "") {
      this.differenceTarget.textContent = "—"
      this.differenceTarget.className = "font-semibold text-[#7a5a56]"
      return
    }

    const diff = parseFloat(physicalRaw) - system
    const sign = diff > 0 ? "+" : ""
    this.differenceTarget.textContent = `${sign}${diff.toFixed(2)}`
    this.differenceTarget.className =
      "font-semibold " +
      (diff < 0 ? "text-[#8f1f2a]" : diff > 0 ? "text-[#25512d]" : "text-[#7a5a56]")
  }
}
