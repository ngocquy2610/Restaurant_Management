import { Controller } from "@hotwired/stimulus"

// Toggles the admin mobile sidebar drawer (off-canvas on smartphones)
// and the mobile backdrop overlay. The dropdown controller is a sibling
// concern and handled separately.
export default class extends Controller {
  static targets = []

  toggle() {
    document.body.classList.toggle("mobile-nav-open")
  }

  close() {
    document.body.classList.remove("mobile-nav-open")
  }
}
