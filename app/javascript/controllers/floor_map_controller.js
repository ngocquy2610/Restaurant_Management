import { Controller } from "@hotwired/stimulus";
import "konva";

const Konva = window.Konva;

// Fill/stroke colors keyed by the Table#status enum value.
const STATUS_STYLES = {
  available: { fill: "#22c55e", stroke: "#15803d" },
  occupied: { fill: "#ef4444", stroke: "#b91c1c" },
  reserved: { fill: "#eab308", stroke: "#a16207" },
  out_of_service: { fill: "#9ca3af", stroke: "#6b7280" },
};

export default class extends Controller {
  static values = { area: Object, tables: Array };

  connect() {
    const area = this.areaValue;
    // Guard against a missing/empty area payload (e.g. no areas configured yet).
    if (!area || !area.width || !area.height) return;

    this.stage = new Konva.Stage({
      container: "konva-stage-container",
      width: area.width,
      height: area.height,
    });

    const layer = new Konva.Layer();
    this.stage.add(layer);

    // "Restaurant layout" background: the room's bounding rectangle.
    layer.add(
      new Konva.Rect({
        x: 0,
        y: 0,
        width: area.width,
        height: area.height,
        fill: "#f7f5f0",
        stroke: "#8f000d",
        strokeWidth: 2,
      }),
    );

    this.tablesValue.forEach((table) => this.renderTable(table, layer));

    layer.draw();
  }

  // Build one Konva.Group per table (label travels with the shape) and expose
  // the table id + position on click. Dragging/moving is intentionally removed
  // — this floor map is read-only and public.
  renderTable(table, layer) {
    const isRound = table.shape === "round";
    const style = STATUS_STYLES[table.status] || STATUS_STYLES.out_of_service;

    // The group sits at the table's (pos_x, pos_y) — which for round tables is
    // the center and for square/rectangle tables the top-left corner, matching
    // the semantics stored in the DB.
    const group = new Konva.Group({
      x: this.num(table.pos_x),
      y: this.num(table.pos_y),
      rotation: this.num(table.rotation),
      draggable: false,
    });

    // Shapes live at the group origin; the group carries the position.
    const common = {
      x: 0,
      y: 0,
      fill: style.fill,
      stroke: style.stroke,
      strokeWidth: 1.5,
      listening: true,
    };

    // Round tables use a radius; square/rectangle tables use width + height.
    let shape;
    if (isRound) {
      shape = new Konva.Circle({ ...common, radius: this.num(table.radius) });
    } else {
      shape = new Konva.Rect({
        ...common,
        width: this.num(table.width),
        height: this.num(table.height),
      });
    }

    // Center a table_number label on the shape (origin of the group = shape
    // top-left for rects / center for circles).
    const label = new Konva.Text({
      x: isRound ? 0 : this.num(table.width) / 2,
      y: isRound ? 0 : this.num(table.height) / 2,
      text: table.table_number,
      fontSize: 13,
      fontFamily: "sans-serif",
      fontStyle: "bold",
      fill: "#ffffff",
      align: "center",
      verticalAlign: "middle",
      shadowColor: "rgba(0,0,0,0.6)",
      shadowBlur: 3,
      // Let pointer events fall through to the shape so drag/hover work on the
      // whole table, not only on the visible area around the number.
      listening: false,
    });
    label.offsetX(label.width() / 2);
    label.offsetY(label.height() / 2);

    group.add(shape);
    group.add(label);

    // Hover cursor feedback (identical pattern to a bare draggable shape).
    group.on("mouseover", () => {
      document.body.style.cursor = "pointer";
    });
    group.on("mouseout", () => {
      document.body.style.cursor = "default";
    });

    // Click: report which table was selected + its position.
    group.on("click", () => this.handleTable("click", table, group));

    // Keep a reference on the shape for programmatic lookups.
    shape.tableId = table.id;

    layer.add(group);
  }

  // Handler for table click. Captures the table id and its position and
  // broadcasts it via a namespaced CustomEvent so the rest of the app can
  // consume it, while also logging it to the console for quick inspection.
  handleTable(action, table, group) {
    const payload = {
      action,
      id: table.id,
      table_number: table.table_number,
      area_id: this.areaValue?.id ?? null,
      pos_x: Math.round(group.x() * 100) / 100,
      pos_y: Math.round(group.y() * 100) / 100,
      rotation: Math.round(group.rotation()),
    };

    console.log(`[floor-map] table ${action}`, payload);

    this.element.dispatchEvent(
      new CustomEvent("floor-map:table-moved", {
        detail: payload,
        bubbles: true,
        cancelable: true,
      }),
    );
  }

  disconnect() {
    this.stage?.destroy();
    this.stage = null;
  }

  num(value) {
    return Number(value) || 0;
  }
}
