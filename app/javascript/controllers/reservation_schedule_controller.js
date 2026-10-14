import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static FIELDS = ["guest_name", "guest_phone", "note"];
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

    const saved = JSON.parse(
      sessionStorage.getItem("reservation_draft") || "null",
    );
    if (saved) {
      this.constructor.FIELDS.forEach((f) => {
        const el = this.element
          .closest("form")
          ?.querySelector(`[name="reservation[${f}]"]`);
        if (el && !el.value) el.value = saved[f] || "";
      });
      sessionStorage.removeItem("reservation_draft");
    }
  }

  selectSlot(event) {
    this.slotTargets.forEach((s) => s.classList.remove("slot-active"));
    event.currentTarget.classList.add("slot-active");
    this.timeTarget.value = event.currentTarget.dataset.time;
  }

  changeDate(event) {
    const date = event.currentTarget.value;
    if (!date) return;

    const form = this.element.closest("form");
    const draft = {};
    this.constructor.FIELDS.forEach((f) => {
      draft[f] = form.querySelector(`[name="reservation[${f}]"]`)?.value || "";
    });
    sessionStorage.setItem("reservation_draft", JSON.stringify(draft));

    const url = this.pathValue.replace("__DATE__", date);
    if (window.Turbo?.visit) {
      window.Turbo.visit(url);
    } else {
      window.location.href = url;
    }
  }
}
