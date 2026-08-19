import { Controller } from "@hotwired/stimulus"

// Generic dropdown toggled by a button. Used for the header Account menu.
// - Clicking the button toggles the menu open/closed.
// - Clicking outside the dropdown (or navigating via Turbo) closes it.
// - Pressing Escape closes it.
export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.outsideClick = this.outsideClick.bind(this)
    this.closeMenu = this.closeMenu.bind(this)
    document.addEventListener("click", this.outsideClick)
    document.addEventListener("turbo:click", this.closeMenu)
  }

  disconnect() {
    document.removeEventListener("click", this.outsideClick)
    document.removeEventListener("turbo:click", this.closeMenu)
  }

  toggle(event) {
    event.stopPropagation()
    this.menuTarget.classList.toggle("hidden")
    this.setExpanded()
  }

  onKeydown(event) {
    if (event.key === "Escape") {
      this.closeMenu()
    }
  }

  outsideClick(event) {
    if (this.element.contains(event.target)) return
    this.closeMenu()
  }

  closeMenu() {
    this.menuTarget.classList.add("hidden")
    this.setExpanded()
  }

  setExpanded() {
    const open = !this.menuTarget.classList.contains("hidden")
    this.element.querySelector("button").setAttribute("aria-expanded", String(open))
  }
}
