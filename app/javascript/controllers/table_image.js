import "konva";

const Konva = window.Konva;

// Table photographs live in public/table_image and are named after the
// (shape, capacity) combo, e.g. "circle_4.png", "square_2.png", "rec_8.png".
export const TABLE_IMAGE_BASE = "/table_image";

// Maps a Table shape enum value to the filename prefix used by the PNG assets.
const SHAPE_TO_PREFIX = {
  square: "square",
  round: "circle",
  rectangle: "rec",
};

// Absolute URL of the table image for a given shape + capacity, or null when
// the shape/capacity don't map to an existing asset.
export function tableImagePath(shape, capacity) {
  const prefix = SHAPE_TO_PREFIX[shape];
  if (!prefix || !capacity) return null;
  return `${TABLE_IMAGE_BASE}/${prefix}_${capacity}.png`;
}

// Build a Konva.Image that renders the table's PNG. `width`/`height` set the
// drawn size; when `center` is true (round tables) the image is offset so it
// sits centred on the node's (x, y) anchor — matching the DB's centre-anchored
// round-table semantics. The image loads asynchronously and redraws on load,
// so the shape is ready to drag/transform immediately and fills in when ready.
export function createTableImageNode({ shape, capacity, width, height, center = false }) {
  const node = new Konva.Image({ width, height, image: undefined });
  if (center) {
    node.offsetX(width / 2);
    node.offsetY(height / 2);
  }

  const src = tableImagePath(shape, capacity);
  if (src) {
    const img = new window.Image();
    img.onload = () => {
      node.image(img);
      node.getLayer()?.draw();
    };
    img.src = src;
  }
  return node;
}
