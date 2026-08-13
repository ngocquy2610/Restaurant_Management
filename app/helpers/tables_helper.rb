module TablesHelper
  # Presentation metadata keyed by the Table#status enum value. `dot` is the
  # bullet colour used in the floor-map legend and stat cards, `chip` is the
  # soft background used for status badges in the table listing.
  STATUS_META = {
    "available"      => { label: "Available",      dot: "bg-green-500",  text: "text-green-700",  chip: "bg-green-100" },
    "occupied"       => { label: "Occupied",       dot: "bg-red-500",    text: "text-red-700",    chip: "bg-red-100" },
    "reserved"       => { label: "Reserved",       dot: "bg-amber-500",  text: "text-amber-700",  chip: "bg-amber-100" },
    "out_of_service" => { label: "Out of service", dot: "bg-gray-400",   text: "text-gray-600",   chip: "bg-gray-100" }
  }.freeze

  def status_meta(status)
    STATUS_META.fetch(status.to_s, STATUS_META["out_of_service"])
  end

  def status_label(status)
    status_meta(status)[:label]
  end

  def status_dot_class(status)
    status_meta(status)[:dot]
  end

  def status_chip_class(status)
    status_meta(status)[:chip]
  end

  # Dropdown options for the capacity field (only the allowed capacities).
  def allowed_capacity_options
    Table::ALLOWED_CAPACITIES.map { |c| ["#{c} guests", c] }
  end

  # Shape options that are valid for a given capacity (e.g. capacity 4 offers
  # Square and Round, capacity 8 offers only Rectangle).
  def shape_options_for_capacity(capacity)
    Table::SHAPE_CAPACITIES
      .select { |_, caps| caps.include?(capacity) }
      .map { |key, _| [key.to_s.humanize, key] }
  end

  # Shape labels for the table listing (shape is stored as an integer enum).
  def shape_label(shape)
    {
      "square" => "Square",
      "round" => "Round",
      "rectangle" => "Rectangle"
    }.fetch(shape.to_s, shape.to_s.humanize)
  end
end
