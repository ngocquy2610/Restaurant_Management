import { Controller } from "@hotwired/stimulus"

// Drives the waiter's order form food picker.
//
// Each item row has:
//   food select      -> options carry data-food-id
//   variant select   -> empty, rebuilt to only show variants of the chosen dish
//   quantity input
//   optional note input
//
// The variants lookup map lives on the controller element as
// `data-order-form-variants' (a JSON object keyed by food id). The user can
// keep the default "No variant" when a dish has no customisation ("if exist").
export default class extends Controller {
  static targets = ["items", "template"]

  connect() {
    this.element.addEventListener("change", this.handleChange)
    // (Re)initialize any server-rendered rows (used when editing an order).
    this.itemsTarget?.querySelectorAll("[data-order-form-row]").forEach((row) => {
      const foodId = row.querySelector("[data-order-form-food]")?.value
      if (foodId) this.updateVariants(row, foodId)
    })
  }

  handleChange = (event) => {
    const foodSelect = event.target.closest("[data-order-form-food]")
    if (!foodSelect) return

    const row = foodSelect.closest("[data-order-form-row]")
    if (row) this.updateVariants(row, foodSelect.value)
  }

  // Append a fresh (empty) item row built from the <template>.
  addItem() {
    if (!this.hasTemplateTarget || !this.hasItemsTarget) return

    const fragment = this.templateTarget.content.cloneNode(true)
    const index = this.nextIndex(fragment)

    fragment.querySelectorAll("[data-order-form-index]").forEach((el) => {
      if (el.name) el.name = el.name.replaceAll("__INDEX__", String(index))
    })

    this.itemsTarget.appendChild(fragment)
    const row = this.itemsTarget.lastElementChild
    if (row) this.updateVariants(row, row.querySelector("[data-order-form-food]")?.value)
  }

  removeItem(event) {
    const row = event.target.closest("[data-order-form-row]")
    if (row) row.remove()
  }

  updateVariants(row, foodId) {
    const variantSelect = row.querySelector("[data-order-form-variant]")
    if (!variantSelect) return

    const variants = (this.variants || {})[foodId] || []
    const previouslySelected = variantSelect.dataset.selectedVariant || ""
    variantSelect.innerHTML = ""

    if (variants.length === 0) {
      variantSelect.add(new Option("No variant", ""))
    } else {
      variantSelect.add(new Option("Choose variation", ""))
      variants.forEach((variant) => {
        variantSelect.add(new Option(variant.name, variant.id))
      })
    }

    // Restore the previously chosen variant (e.g. when editing) if still valid.
    if ([...variantSelect.options].some((o) => o.value === previouslySelected)) {
      variantSelect.value = previouslySelected
    }
  }

  // Index for freshly appended rows = current number of rendered rows.
  nextIndex(fragment) {
    return this.itemsTarget.querySelectorAll("[data-order-form-row]").length
  }

  get variants() {
    try {
      return JSON.parse(this.element.dataset.orderFormVariants || "{}")
    } catch {
      return {}
    }
  }
}