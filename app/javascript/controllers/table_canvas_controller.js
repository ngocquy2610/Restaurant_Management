import { Controller } from "@hotwired/stimulus";
import "konva";
import { createTableImageNode } from "controllers/table_image";

const Konva = window.Konva;

// Must match the read-only floor-map viewer (floor_map_controller.js) so saved
// pos_x/pos_y/width/height/radius/rotation line up between editor and viewer.
const STAGE_WIDTH = 1200;
const STAGE_HEIGHT = 700;

// Default geometry for a freshly placed shape, centered on the stage.
// Table sizes are FIXED per shape and cannot be resized by the user:
//   square  -> 150 x 150
//   rect    -> 300 x 150
//   round   -> radius 75 (150 diameter, matching the 150 x 150 square)
const DEFAULT_GEOMETRY = {
  square: { width: 150, height: 150 },
  rectangle: { width: 300, height: 150 },
  round: { radius: 75 },
};

// Drawn size for the table images, matching DEFAULT_GEOMETRY's fixed
// footprints (square & round are 150 x 150, rectangle is 300 x 150).
const IMAGE_SIZE = {
  square: { width: 150, height: 150 },
  rectangle: { width: 300, height: 150 },
  round: { width: 150, height: 150 },
};

// Renders the editable table on a Konva stage and syncs its live geometry
// into the form's hidden inputs. The table is drawn from the photo stored in
// public/table_image (selected by shape + capacity), so the admin sees the
// exact image that will appear on the floor plan.
//
// New tables start from a centered default; editing an existing table restores
// its persisted geometry from the hidden inputs whenever the relevant fields
// carry a value. Rebuilds whenever the table-wizard dispatches "shape-selected".
export default class extends Controller {
  static values = { shape: String, areas: Object, areaImages: Object };
  static targets = [
    "canvasContainer",
    "posX",
    "posY",
    "width",
    "height",
    "radius",
    "rotation",
    "submitBtn",
  ];

  connect() {
    this.stage = new Konva.Stage({
      container: this.canvasContainerTarget,
      width: STAGE_WIDTH,
      height: STAGE_HEIGHT,
    });

    this.layer = new Konva.Layer();
    this.stage.add(this.layer);

    // Room backdrop: draw the selected area's uploaded floor-map image full-bleed
    // (still 1200x700) when one exists, mirroring the read-only floor-map viewer.
    this.renderBackground();

    this.shape = null;
    this.existingGroup = null;
    // resizeEnabled:false locks the table to its fixed shape size (see
    // DEFAULT_GEOMETRY) — the admin can still drag to move and grab the rotate
    // handle, but the resizing corner/edge handles are hidden.
    this.transformer = new Konva.Transformer({ resizeEnabled: false });

    // Edit mode: geometry is already persisted, so restore it immediately rather
    // than waiting for the admin to re-select a shape in step one.
    if (this.shapeValue) {
      this.renderShape(this.shapeValue);
    }

    // The wizard notifies us via a bubbling CustomEvent whenever it wants the
    // currently selected shape (re)drawn.
    this.handleShapeSelected = (event) => this.renderShape(event.detail.shape);
    document.addEventListener("shape-selected", this.handleShapeSelected);

    // Keep the 1200x700 map fully visible by scaling it down to fit the
    // container width on narrower screens (no clipping).
    this.handleResize = () => this.fitStage();
    window.addEventListener("resize", this.handleResize);
    this.fitStage();

    this.layer.draw();
  }

  // Scale the fixed 1200x700 stage down to fit the canvas container's width so
  // the entire floor map is always visible (never clipped on narrower viewports).
  // The internal 1200x700 coordinate space is preserved, so saved geometry stays
  // consistent with the read-only floor-map viewer.
  fitStage() {
    const container = this.canvasContainerTarget;
    const available = (container && container.clientWidth) || STAGE_WIDTH;
    const scale = Math.min(1, available / STAGE_WIDTH);

    this.stage.width(STAGE_WIDTH * scale);
    this.stage.height(STAGE_HEIGHT * scale);
    this.stage.scale({ x: scale, y: scale });
    this.layer.draw();
  }

  // Draw the selected area's uploaded floor-map image as the room backdrop,
  // mirroring the read-only floor-map viewer. Falls back to the solid interior
  // rectangle when the area has no image. All nodes use listening:false so they
  // never intercept drags aimed at the editable table shape.
  renderBackground() {
    if (this.backgroundNode) {
      this.backgroundNode.destroy();
      this.backgroundNode = null;
    }

    const images = this.areaImagesValue || {};
    const imageUrl = images[this.currentAreaId()];

    if (imageUrl) {
      const img = new window.Image();
      img.onload = () => {
        this.backgroundNode = new Konva.Image({
          x: 0,
          y: 0,
          width: STAGE_WIDTH,
          height: STAGE_HEIGHT,
          image: img,
          listening: false,
        });
        this.layer.add(this.backgroundNode);
        this.backgroundNode.moveToBottom();
        this.layer.draw();
      };
      img.src = imageUrl;
    } else {
      this.backgroundNode = new Konva.Rect({
        x: 0,
        y: 0,
        width: STAGE_WIDTH,
        height: STAGE_HEIGHT,
        fill: "#f7f5f0",
        stroke: "#8f000d",
        strokeWidth: 2,
        listening: false,
      });
      this.layer.add(this.backgroundNode);
      this.backgroundNode.moveToBottom();
    }
  }

  // Build (or rebuild) the selectable shape. Rebuilding happens on first arrival
  // at step two, or when the admin goes back and changes the shape.
  renderShape(shape) {
    if (this.shape) {
      this.shape.destroy();
      this.shape = null;
    }
    if (this.transformer.nodes().length) {
      this.transformer.detach();
    }

    const isRound = shape === "round";
    const stored = this.storedGeometry(shape);
    this.isRound = isRound;

    this.shape = this.buildImage(shape, stored);

    // Show the tables already placed in the selected area so the admin can
    // position this one in relation to them (read-only, underneath the editor).
    this.renderExistingTables();
    // Re-evaluate the backdrop too, in case the admin changed the selected area
    // back in step one before arriving here.
    this.renderBackground();

    this.layer.add(this.shape);
    this.layer.add(this.transformer);
    this.transformer.nodes([this.shape]);

    this.bindShapeEvents(this.shape, isRound);
    this.syncFieldsFromShape(this.shape);
    this.enableSubmit();
    // Re-fit after the wizard reveals step two so the map fills the now-visible
    // container (clientWidth is measured after the hidden class is removed).
    this.fitStage();
    this.layer.draw();
  }

  // Build (or rebuild) the draggable table image. The photo is chosen from
  // public/table_image via the current shape + capacity, so the exact image
  // the user picked is displayed and will be saved for the floor plan.
  buildImage(shape, stored) {
    const isRound = shape === "round";
    const size = IMAGE_SIZE[shape] || IMAGE_SIZE.square;
    const capacity = this.currentCapacity();

    const x =
      stored && stored.x != null
        ? stored.x
        : isRound
          ? STAGE_WIDTH / 2
          : (STAGE_WIDTH - size.width) / 2;
    const y =
      stored && stored.y != null
        ? stored.y
        : isRound
          ? STAGE_HEIGHT / 2
          : (STAGE_HEIGHT - size.height) / 2;

    const node = createTableImageNode({
      shape,
      capacity,
      width: size.width,
      height: size.height,
      center: isRound,
    });
    node.x(x);
    node.y(y);
    node.rotation(stored && stored.rotation != null ? stored.rotation : 0);
    node.draggable(true);
    node.listening(true);
    return node;
  }

  // Pull persisted geometry from the hidden inputs, but only for the current
  // shape type and only from fields that actually hold a value. This avoids
  // restoring a square's size onto a round table when the admin changes shape
  // mid-edit.
  storedGeometry(shape) {
    if (shape === "round") {
      if (this.radiusTarget.value === "") return null;
      return {
        x: this.num(this.posXTarget.value),
        y: this.num(this.posYTarget.value),
        radius: this.num(this.radiusTarget.value),
      };
    }

    if (this.widthTarget.value === "" || this.heightTarget.value === "")
      return null;
    return {
      x: this.num(this.posXTarget.value),
      y: this.num(this.posYTarget.value),
      width: this.num(this.widthTarget.value),
      height: this.num(this.heightTarget.value),
      rotation: this.num(this.rotationTarget.value),
    };
  }

  // Render the tables already placed in the currently selected area as
  // read-only context (passive — never draggable, never forwarded to the form).
  renderExistingTables() {
    if (this.existingGroup) {
      this.existingGroup.destroy();
    }
    this.existingGroup = new Konva.Group();

    const areaId = this.currentAreaId();
    const tables = (areaId && this.areasValue && this.areasValue[areaId]) || [];
    tables.forEach((table) => this.renderExistingTable(table));

    this.layer.add(this.existingGroup);
  }

  // One read-only table, using the same photo as the floor-map viewer. All
  // nodes use listening:false so the existing tables never intercept drags or
  // clicks meant for the editable shape on top.
  renderExistingTable(table) {
    const isRound = table.shape === "round";
    const width = isRound ? this.num(table.radius) * 2 : this.num(table.width);
    const height = isRound
      ? this.num(table.radius) * 2
      : this.num(table.height);

    const group = new Konva.Group({
      x: this.num(table.pos_x),
      y: this.num(table.pos_y),
      rotation: this.num(table.rotation),
      listening: false,
    });

    const shape = createTableImageNode({
      shape: table.shape,
      capacity: table.capacity,
      width,
      height,
      center: isRound,
    });
    shape.listening(false);
    group.add(shape);

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
      listening: false,
    });
    label.offsetX(label.width() / 2);
    label.offsetY(label.height() / 2);

    group.add(label);
    this.existingGroup.add(group);
  }

  // The area currently selected in step one (pre-filled on edit).
  currentAreaId() {
    const form = this.element.closest("form");
    const field = form
      ? form.querySelector("select[name='table[area_id]']")
      : null;
    return field && field.value ? field.value : null;
  }

  // The capacity currently selected in step one (pre-filled on edit). Drives
  // which photo from public/table_image is shown for this table.
  currentCapacity() {
    const form = this.element.closest("form");
    const field = form
      ? form.querySelector("select[name='table[capacity]']")
      : null;
    return field && field.value ? field.value : null;
  }

  // Keep the shape anchored to relevant drag events.
  bindShapeEvents(shape, isRound) {
    // Keep the shape inside the stage while dragging. Round tables anchor on
    // their center; square/rectangle tables on their top-left corner (matching
    // the semantics the read-only viewer expects).
    shape.dragBoundFunc((pos) => {
      if (isRound) {
        const r = shape.width() / 2;
        return {
          x: Math.min(Math.max(pos.x, r), STAGE_WIDTH - r),
          y: Math.min(Math.max(pos.y, r), STAGE_HEIGHT - r),
        };
      }
      return {
        x: Math.min(Math.max(pos.x, 0), STAGE_WIDTH - shape.width()),
        y: Math.min(Math.max(pos.y, 0), STAGE_HEIGHT - shape.height()),
      };
    });

    shape.on("dragmove", () => this.syncFieldsFromShape(shape));

    // Size is fixed per shape (see DEFAULT_GEOMETRY), so a rotate gesture only
    // needs to persist the new angle — the dimensions never change.
    shape.on("transformend", () => {
      this.syncFieldsFromShape(shape);
      this.layer.draw();
    });
  }

  // Write the shape's live geometry into the hidden inputs, clearing the
  // dimension fields that don't apply to the current shape. Round tables are
  // persisted as a radius (half the image's diameter).
  syncFieldsFromShape(shape) {
    if (!shape) return;
    const isRound = this.isRound;

    this.posXTarget.value = String(this.round2(shape.x()));
    this.posYTarget.value = String(this.round2(shape.y()));
    this.rotationTarget.value = String(shape.rotation());

    if (isRound) {
      this.radiusTarget.value = String(this.round2(shape.width() / 2));
      this.widthTarget.value = "";
      this.heightTarget.value = "";
    } else {
      this.widthTarget.value = String(this.round2(shape.width()));
      this.heightTarget.value = String(this.round2(shape.height()));
      this.radiusTarget.value = "";
    }
  }

  enableSubmit() {
    this.submitBtnTarget.disabled = false;
  }

  round2(value) {
    return Math.round(Number(value) * 100) / 100;
  }

  num(value) {
    const n = Number(value);
    return Number.isFinite(n) ? n : 0;
  }

  disconnect() {
    window.removeEventListener("resize", this.handleResize);
    document.removeEventListener("shape-selected", this.handleShapeSelected);
    this.existingGroup?.destroy();
    this.stage?.destroy();
    this.stage = null;
  }
}
