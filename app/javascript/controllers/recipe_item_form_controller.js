import { Controller } from "@hotwired/stimulus"

// Drives the recipe item form's dependent "Food variant" dropdown so it only
// shows variants belonging to the currently selected Food.
export default class extends Controller {
  static targets = ["food", "variant"]
  static values = { variants: Object }

  connect() {
    this.updateVariants()
  }

  updateVariants() {
    const foodId = this.foodTarget.value
    const currentlySelected = this.variantTarget.value
    const variants = this.variantsValue[foodId] || []

    this.variantTarget.innerHTML = ""
    this.variantTarget.add(new Option("No variant (base recipe)", ""))

    variants.forEach((variant) => {
      this.variantTarget.add(new Option(variant.name, variant.id))
    })

    // Re-apply the previously chosen variant when it is still valid for this food.
    this.variantTarget.value = currentlySelected
  }
}
