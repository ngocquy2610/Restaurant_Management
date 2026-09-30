import { Controller } from "@hotwired/stimulus";

// Star picker for review ratings: previews on hover, commits on click, and
// reflects the already-checked rating when the form re-renders (edit / validation error).
export default class extends Controller {
  static targets = ["star", "input", "label"];
  static values = {
    labels: {
      type: Array,
      default: ["Bad", "Poor", "Okay", "Good", "Excellent"],
    },
  };

  connect() {
    this.refresh();
  }

  preview(event) {
    this.paint(Number(event.currentTarget.dataset.value));
  }
  reset() {
    this.refresh();
  }

  select(event) {
    const value = event.currentTarget.dataset.value;
    const input = this.inputTargets.find(
      (candidate) => candidate.value === value,
    );
    if (!input) return;
    input.checked = true;
    this.refresh();
  }

  refresh() {
    const checked = this.inputTargets.find((input) => input.checked);
    this.paint(checked ? Number(checked.value) : 0);
  }

  paint(rating) {
    this.starTargets.forEach((star) => {
      const filled = Number(star.dataset.value) <= rating;
      star.classList.toggle("text-amber-400", filled);
      star.classList.toggle("text-gray-300", !filled);
    });
    if (this.hasLabelTarget) {
      this.labelTarget.textContent =
        rating > 0 ? this.labelsValue[rating - 1] : "";
    }
  }
}
