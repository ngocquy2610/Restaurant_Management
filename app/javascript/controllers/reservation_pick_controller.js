import { Controller } from "@hotwired/stimulus";

// Listens for the `floor-map:table-moved` event that the floor-map controller
// dispatches when a table shape is clicked, then opens the reservation form
// pre-selected to that table.
//
// Any table can be clicked — the availability of the 2-hour meal slots is shown
// on the reservation form itself, not on the floor plan.
export default class extends Controller {
  static values = { path: String };

  connect() {
    this.element.addEventListener("floor-map:table-moved", this.onTableMove);
  }

  disconnect() {
    this.element.removeEventListener("floor-map:table-moved", this.onTableMove);
  }

  onTableMove = (event) => {
    const { id } = event.detail || {};
    if (!id) return;

    const url = this.pathValue.replace("__TABLE_ID__", id);
    if (window.Turbo?.visit) {
      window.Turbo.visit(url);
    } else {
      window.location.href = url;
    }
  };
}
