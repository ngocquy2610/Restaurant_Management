import { Controller } from "@hotwired/stimulus"

// Live preview + character count + duplicate-name hint for the category form.
// Existing names are passed via data-category-form-existing-value (JSON array).
export default class extends Controller {
  static targets = ["input", "counter", "preview", "duplicate", "submit"]
  static values = { existing: Array }

  connect() {
    this.update()
  }

  update() {
    const raw = this.hasInputTarget ? this.inputTarget.value : ""
    const value = raw.trim()
    const len = [...raw].length

    if (this.hasCounterTarget) {
      this.counterTarget.textContent = `${len} / 60`
      this.counterTarget.classList.toggle("bg-[#fbe9e6]", len > 60 || len === 1)
      this.counterTarget.classList.toggle("text-[#8f1f2a]", len > 60 || len === 1)
    }

    if (this.hasPreviewTarget) {
      this.previewTarget.textContent = value || "Your category name"
    }

    const names = (this.existingValue || []).map((n) => n.toLowerCase())
    const isDuplicate = value.length > 0 && names.includes(value.toLowerCase())

    if (this.hasDuplicateTarget) {
      if (isDuplicate) {
        this.duplicateTarget.textContent = `⚠ “${value}” already exists — names must be unique (case-insensitive).`
        this.duplicateTarget.classList.remove("hidden")
      } else {
        this.duplicateTarget.textContent = ""
        this.duplicateTarget.classList.add("hidden")
      }
    }

    if (this.hasSubmitTarget) {
      const tooShort = value.length === 1
      const tooLong = len > 60
      this.submitTarget.disabled = tooShort || tooLong || isDuplicate
      this.submitTarget.title = isDuplicate
        ? "This name is already taken"
        : tooShort
          ? "Name must be at least 2 characters (or blank to cancel)"
          : tooLong
            ? "Name must be 60 characters or fewer"
            : ""
    }
  }
}
