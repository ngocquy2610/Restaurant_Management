import { Controller } from "@hotwired/stimulus";

// Listens for the `floor-map:table-moved` event that the floor-map controller
// dispatches when a table shape is clicked, then opens the reservation form
// pre-selected to that table.
export default class extends Controller {
  static values = { path: String };

  connect() {
    this.element.addEventListener("floor-map:table-moved", this.onTableMove);
  }

  disconnect() {
    this.element.removeEventListener("floor-map:table-moved", this.onTableMove);
  }

  onTableMove = (event) => {
    const { id, status } = event.detail || {};
    if (!id) return;

    // A table that's already reserved, occupied, or out of service cannot be
    // booked — don't navigate to the reservation form for it.
    if (["reserved", "occupied", "out_of_service"].includes(status)) return;

    const url = this.pathValue.replace("__TABLE_ID__", id);
    if (window.Turbo?.visit) {
      window.Turbo.visit(url);
    } else {
      window.location.href = url;
    }
  };
}
