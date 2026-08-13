import { Controller } from "@hotwired/stimulus";

// Allowed seating capacities and the table shapes that support each. Mirrors
// Table::SHAPE_CAPACITIES on the backend so the dropdowns stay in sync.
const ALLOWED_CAPACITIES = [2, 4, 6, 8, 10];
const SHAPE_CAPACITIES = {
  square: [2, 4],
  round: [4, 6],
  rectangle: [6, 8, 10],
};

// Drives the two-step "new/edit table" wizard. Step one collects the descriptive
// fields; step two hosts the Konva floor-map editor (a separate controller).
//
// The two sections live inside a single <form>, so this controller only toggles
// their visibility and dispatches a "shape-selected" CustomEvent so the canvas
// controller knows which shape to draw. Form submission happens once, at the end
// of step two.
export default class extends Controller {
  static values = {
    areas: Object,
    tableTypes: Object,
    areaTables: Object,
    creating: Boolean,
  };

  static targets = [
    "stepOne",
    "stepTwo",
    "errorAlert",
    "progressOne",
    "progressTwo",
    "progressLine",
    "shapePreview",
    "areaSelect",
    "tableTypeSelect",
    "tableNumberField",
    "tableNumberHint",
  ];

  connect() {
    // Start on step one with the progress indicator in its initial state.
    this.markStep(this.progressOneTarget, "active", "1");
    this.markStep(this.progressTwoTarget, "idle", "2");
    this.setLine(false);
    this.renderShapePreview();
    // Restrict the shape dropdown to the shapes that support the current
    // capacity (keeps an existing, valid selection intact).
    this.rebuildShapeOptions();
    // Pre-fill the auto-generated table number if the area/type were already
    // chosen (e.g. a re-rendered form after a validation error).
    if (this.creatingValue) this.recomputeTableNumber();
  }

  // Validate step one before revealing step two. If any [required] field is
  // invalid we surface the native browser feedback, focus the first problem,
  // and show an inline alert — we never advance with bad step-one data.
  goToStepTwo() {
    const required = [...this.stepOneTarget.querySelectorAll("[required]")];
    const invalid = required.filter((field) => !field.checkValidity());

    if (invalid.length) {
      // Native bubbles, focused for immediate correction, plus a summary alert.
      invalid.forEach((field) => field.reportValidity());
      const fields = invalid
        .map((field) => this.fieldLabel(field))
        .filter(Boolean)
        .join(", ");
      this.showError(`Please complete the highlighted fields before continuing: ${fields}.`);
      invalid[0].focus();
      return;
    }

    this.hideError();
    this.hide(this.stepOneTarget);
    this.show(this.stepTwoTarget);

    this.markStep(this.progressOneTarget, "done", "1");
    this.markStep(this.progressTwoTarget, "active", "2");
    this.setLine(true);

    this.dispatchShapeSelected();
  }

  goToStepOne() {
    this.hide(this.stepTwoTarget);
    this.show(this.stepOneTarget);

    this.markStep(this.progressOneTarget, "active", "1");
    this.markStep(this.progressTwoTarget, "idle", "2");
    this.setLine(false);
  }

  // The admin may change the shape after having already seen step two (e.g.
  // they went Back, switched square -> round, then returned). Re-dispatch so the
  // canvas redraws immediately and stays in sync — and refresh the live preview.
  // Changing shape also narrows the capacity choices to what that shape can hold.
  shapeChanged() {
    this.rebuildCapacityOptions();
    this.renderShapePreview();
    this.dispatchShapeSelected();
  }

  // Picking a capacity narrows the shape dropdown to the shapes that can seat
  // that many guests (e.g. capacity 8 -> only Rectangle).
  capacityChanged() {
    this.rebuildShapeOptions();
    this.renderShapePreview();
    this.dispatchShapeSelected();
  }

  // Recompute the auto-generated table number from the selected area + type:
  // "area first char" repeated twice + "type first char" + the lowest unused
  // index (start at 1 and bump while that exact number already exists in the
  // chosen area). Mirrors Table#generate_table_number on the backend.
  recomputeTableNumber() {
    if (!this.creatingValue) return;

    const areaKey = this.areaSelectTarget?.value;
    const typeKey = this.tableTypeSelectTarget?.value;

    if (!areaKey || !typeKey) {
      this.setTableNumber("", false);
      return;
    }

    const areaName = this.areasValue[areaKey] || "";
    const typeName = this.tableTypesValue[typeKey] || "";
    const firstChar = (s) => s.trim().charAt(0).toUpperCase();

    const areaChar = firstChar(areaName);
    const typeChar = firstChar(typeName);
    if (!areaChar || !typeChar) {
      this.setTableNumber("", false);
      return;
    }

    const prefix = `${areaChar}${areaChar}${typeChar}`;
    const taken = new Set((this.areaTablesValue[areaKey] || []).map((t) => t.table_number));

    let index = 1;
    while (taken.has(`${prefix}${index}`)) index += 1;

    this.setTableNumber(`${prefix}${index}`, true);
  }

  // Fill the (read-only) table number field and reflect its state in the hint.
  setTableNumber(value, generated) {
    if (!this.hasTableNumberField) return;
    if (this.tableNumberFieldTarget.value === value) return;

    this.tableNumberFieldTarget.value = value;
    if (this.hasTableNumberHint) {
      this.tableNumberHintTarget.textContent = generated
        ? `Auto-generated as ${value}.`
        : "Select an area and table type to auto-generate the table number.";
    }
  }

  // Rebuild the shape dropdown using only the shapes that support the selected
  // capacity. If the currently selected shape is no longer valid, fall back to
  // the first allowed shape.
  rebuildShapeOptions() {
    const shapeField = this.stepOneTarget.querySelector("select[name='table[shape]']");
    const capacityField = this.stepOneTarget.querySelector("select[name='table[capacity]']");
    if (!shapeField || !capacityField) return;

    const capacity = parseInt(capacityField.value, 10);
    const allowedShapes = Number.isNaN(capacity)
      ? Object.keys(SHAPE_CAPACITIES)
      : Object.keys(SHAPE_CAPACITIES).filter((s) => SHAPE_CAPACITIES[s].includes(capacity));

    const current = shapeField.value;
    shapeField.innerHTML = allowedShapes
      .map((s) => `<option value="${s}">${s.charAt(0).toUpperCase() + s.slice(1)}</option>`)
      .join("");

    if (allowedShapes.length && !allowedShapes.includes(current)) {
      shapeField.value = allowedShapes[0];
    }
  }

  // Rebuild the capacity dropdown using only the capacities the selected shape
  // can seat. If the current capacity doesn't fit that shape, pick the first
  // allowed value.
  rebuildCapacityOptions() {
    const shapeField = this.stepOneTarget.querySelector("select[name='table[shape]']");
    const capacityField = this.stepOneTarget.querySelector("select[name='table[capacity]']");
    if (!shapeField || !capacityField) return;

    const shape = shapeField.value;
    const allowedCapacities = (shape && SHAPE_CAPACITIES[shape]) || ALLOWED_CAPACITIES;
    const current = parseInt(capacityField.value, 10);

    capacityField.innerHTML = allowedCapacities
      .map((c) => `<option value="${c}">${c} guests</option>`)
      .join("");

    if (!Number.isNaN(current) && !allowedCapacities.includes(current)) {
      capacityField.value = String(allowedCapacities[0]);
    }
  }

  dispatchShapeSelected() {
    const shape = this.currentShape();
    if (!shape) return;

    this.element.dispatchEvent(
      new CustomEvent("shape-selected", {
        detail: { shape },
        bubbles: true,
      }),
    );
  }

  currentShape() {
    const field = this.stepOneTarget.querySelector("select[name='table[shape]']");
    return field ? field.value : null;
  }

  // Human-readable label for a field, looked up from its associated <label>.
  fieldLabel(field) {
    const label = field.id && this.stepOneTarget.querySelector(`label[for='${field.id}']`);
    return label ? label.textContent.trim() : field.name;
  }

  // Renders a small SVG preview of the currently selected table shape.
  renderShapePreview() {
    const el = this.shapePreviewTarget;
    if (!el) return;

    const shape = this.currentShape();
    const defs = {
      square: {
        svg: '<svg viewBox="0 0 120 120" fill="none" xmlns="http://www.w3.org/2000/svg" class="h-16 w-16"><rect x="20" y="20" width="80" height="80" rx="16" fill="#8A1C2B" fill-opacity="0.10" stroke="#8A1C2B" stroke-width="3"/></svg>',
        name: "Square",
        note: "Ideal for 2–4 guests",
      },
      rectangle: {
        svg: '<svg viewBox="0 0 160 100" fill="none" xmlns="http://www.w3.org/2000/svg" class="h-16 w-24"><rect x="20" y="20" width="120" height="60" rx="16" fill="#8A1C2B" fill-opacity="0.10" stroke="#8A1C2B" stroke-width="3"/></svg>',
        name: "Rectangle",
        note: "Great for larger parties",
      },
      round: {
        svg: '<svg viewBox="0 0 120 120" fill="none" xmlns="http://www.w3.org/2000/svg" class="h-16 w-16"><circle cx="60" cy="60" r="40" fill="#8A1C2B" fill-opacity="0.10" stroke="#8A1C2B" stroke-width="3"/></svg>',
        name: "Round",
        note: "Social seating for 4–6",
      },
    };

    const def = defs[shape];
    if (!def) {
      el.innerHTML = "";
      return;
    }

    el.innerHTML = `
      <div class="flex flex-col items-center gap-3">
        <div class="flex h-16 w-16 items-center justify-center">${def.svg}</div>
        <div class="text-center">
          <p class="text-sm font-semibold text-gray-900">${def.name}</p>
          <p class="text-xs text-gray-500">${def.note}</p>
        </div>
      </div>`;
  }

  // Drive the numbered step circles between active / done / idle styles, fill the
  // circle with a checkmark once a step is complete, or show its step number.
  markStep(step, state, number = "") {
    const circle = step.querySelector(".progress-circle");
    if (!circle) return;

    const base = "flex h-9 w-9 shrink-0 items-center justify-center rounded-full border-2 text-sm font-bold transition";
    const styles = {
      active: "border-[#8A1C2B] bg-[#8A1C2B] text-white",
      done: "border-green-500 bg-green-500 text-white",
      idle: "border-gray-300 bg-white text-gray-400",
    };
    circle.className = `${base} ${styles[state]}`;
    circle.innerHTML = state === "done" ? "✓" : (state === "active" ? number : "");
  }

  setLine(filled) {
    const line = this.progressLineTarget;
    if (!line) return;
    line.className = filled
      ? "h-0.5 w-full rounded-full bg-[#8A1C2B] transition"
      : "h-0.5 w-full rounded-full bg-gray-200 transition";
  }

  showError(message) {
    const alert = this.errorAlertTarget;
    if (!alert) return;
    alert.textContent = message;
    alert.classList.remove("hidden");
  }

  hideError() {
    const alert = this.errorAlertTarget;
    if (!alert) return;
    alert.textContent = "";
    alert.classList.add("hidden");
  }

  show(element) {
    element.classList.remove("hidden");
  }

  hide(element) {
    element.classList.add("hidden");
  }
}
