import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["time", "slot", "date"];
  static values = { path: String, date: String };

  connect() {
    // Highlight slot tương ứng với giá trị đang chọn (nếu có) khi load lại.
    this.slotTargets.forEach((s) => {
      s.classList.toggle(
        "slot-active",
        s.dataset.time === this.timeTarget.value,
      );
    });
  }

  selectSlot(event) {
    this.slotTargets.forEach((s) => s.classList.remove("slot-active"));
    event.currentTarget.classList.add("slot-active");
    this.timeTarget.value = event.currentTarget.dataset.time;
  }

  changeDate(event) {
    const date = event.currentTarget.value;
    if (!date) return;
    const url = this.pathValue.replace("__DATE__", date);
    if (window.Turbo?.visit) {
      window.Turbo.visit(url);
    } else {
      window.location.href = url;
    }
  }
}
