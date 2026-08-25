import { Controller } from "@hotwired/stimulus"

// Promotional image slideshow for the homepage hero.
// - Auto-advances every `intervalValue` milliseconds.
// - The "Next" button advances one slide (wraps around past the last one).
// - Dots indicate the current slide and let you jump directly to it.
// - Pauses while the mouse hovers over the slider.
export default class extends Controller {
  static targets = ["slide", "dot", "controls"]
  static values = { interval: { type: Number, default: 4500 } }

  connect() {
    this.current = 0

    if (this.slideTargets.length <= 1) {
      this.controlsTargets.forEach((node) => node.classList.add("hidden"))
      this.dotTargets.forEach((dot) => dot.classList.add("hidden"))
      return
    }

    this.goTo(this.current)
    this.startTimer()

    this.pause = this.pause.bind(this)
    this.resume = this.resume.bind(this)
    this.element.addEventListener("mouseenter", this.pause)
    this.element.addEventListener("mouseleave", this.resume)
  }

  disconnect() {
    this.stopTimer()
    this.element.removeEventListener("mouseenter", this.pause)
    this.element.removeEventListener("mouseleave", this.resume)
  }

  next() {
    this.goTo(this.current + 1)
  }

  prev() {
    this.goTo(this.current - 1)
  }

  goTo(index) {
    const total = this.slideTargets.length
    if (total <= 1) return

    // Wrap around (loop) so Next always has a slide to move to when there is more than one.
    this.current = (index + total) % total
    if (this.indexAdvancePaused) this.resume()
    this.render()
  }

  render() {
    this.slideTargets.forEach((slide, i) => {
      slide.classList.toggle("is-visible", i === this.current)
    })
    this.dotTargets.forEach((dot, i) => {
      dot.classList.toggle("is-active", i === this.current)
    })
  }

  dot(event) {
    const index = parseInt(event.currentTarget.dataset.index, 10)
    this.goTo(index)
  }

  startTimer() {
    this.stopTimer()
    this.timer = window.setInterval(() => {
      if (!this.indexAdvancePaused) {
        this.current = (this.current + 1) % this.slideTargets.length
        this.render()
      }
    }, this.intervalValue)
  }

  stopTimer() {
    if (this.timer) window.clearInterval(this.timer)
    this.timer = null
  }

  pause() {
    this.indexAdvancePaused = true
  }

  resume() {
    this.indexAdvancePaused = false
    // Restart with a fresh interval so it doesn't advance immediately after hover ends.
    this.startTimer()
  }
}