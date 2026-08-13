import { Controller } from "@hotwired/stimulus";
import "konva";
import { createTableImageNode } from "controllers/table_image";

const Konva = window.Konva;

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

    // If the area has an uploaded floor-map image, use it as a full-bleed
    // background (still drawn at the room's fixed 1200x700 size). Otherwise
    // fall back to the plain "restaurant layout" bounding rectangle.
    if (area.image) {
      const img = new window.Image();
      img.onload = () => {
        const bg = new Konva.Image({
          x: 0,
          y: 0,
          width: area.width,
          height: area.height,
          image: img,
          listening: false,
        });
        layer.add(bg);
        bg.moveToBottom();
        layer.draw();
      };
      img.src = area.image;
    } else {
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
    }

    this.tablesValue.forEach((table) => this.renderTable(table, layer));

    layer.draw();
  }

  // Build one Konva.Group per table (label travels with the shape) and expose
  // the table id + position on click. Dragging/moving is intentionally removed
  // — this floor map is read-only and public. Each table is drawn from its
  // photo in public/table_image (chosen by shape + capacity).
  renderTable(table, layer) {
    const isRound = table.shape === "round";
    const width = isRound ? this.num(table.radius) * 2 : this.num(table.width);
    const height = isRound
      ? this.num(table.radius) * 2
      : this.num(table.height);

    // The group sits at the table's (pos_x, pos_y) — which for round tables is
    // the center and for square/rectangle tables the top-left corner, matching
    // the semantics stored in the DB.
    const group = new Konva.Group({
      x: this.num(table.pos_x),
      y: this.num(table.pos_y),
      rotation: this.num(table.rotation),
      draggable: false,
    });

    // The table image sits at the group origin; the group carries the position.
    // For round tables the image is offset so it stays centred on the origin.
    const shape = createTableImageNode({
      shape: table.shape,
      capacity: table.capacity,
      width,
      height,
      center: isRound,
    });
    shape.listening(true);
    group.add(shape);

    // Center a table_number label on the shape (origin of the group = shape
    // top-left for rects / center for circles).
    const label = new Konva.Text({
      x: isRound ? 0 : width / 2,
      y: isRound ? 0 : height / 2,
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
