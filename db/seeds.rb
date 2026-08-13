# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# -----------------------------------------------------------------------------
# Table Types
# -----------------------------------------------------------------------------
table_types = [
  { type: "Standard", price_add_on: 0.0 },
  { type: "VIP",      price_add_on: 50.0 },
  { type: "Booth",    price_add_on: 30.0 }
]

table_type_records = {}

table_types.each do |attrs|
  tt = TableType.find_or_create_by!(type: attrs[:type]) do |t|
    t.price_add_on = attrs[:price_add_on]
  end
  table_type_records[attrs[:type]] = tt
  puts "TableType: #{tt.type}"
end

# -----------------------------------------------------------------------------
# Areas
# -----------------------------------------------------------------------------
areas = [
  { name: "Main Dining Floor", area_type: :indoor,  floor_level: 1 },
  { name: "Rooftop Terrace",   area_type: :outdoor, floor_level: 5 },
  { name: "Private Lounge",    area_type: :indoor,  floor_level: 2 }
]

areas.each do |attrs|
  area = Area.find_or_create_by!(name: attrs[:name]) do |a|
    a.area_type = attrs[:area_type]
    a.floor_level = attrs[:floor_level]
  end
  puts "Area: #{area.name}"
end

# -----------------------------------------------------------------------------
# Tables
# -----------------------------------------------------------------------------
standard = table_type_records["Standard"]
vip      = table_type_records["VIP"]
booth    = table_type_records["Booth"]

main_floor    = Area.find_by!(name: "Main Dining Floor")
rooftop       = Area.find_by!(name: "Rooftop Terrace")
private_lounge = Area.find_by!(name: "Private Lounge")

# Each entry: [table_number, table_type, shape, capacity, status, layout]
tables = [
  # Main Dining Floor (square tables)
  ["M1", standard, :square, 2, :available, { pos_x: 120, pos_y: 80,  width: 60, height: 60, rotation: 0 }],
  ["M2", standard, :square, 2, :available, { pos_x: 240, pos_y: 80,  width: 60, height: 60, rotation: 0 }],
  ["M3", standard, :square, 4, :occupied,  { pos_x: 120, pos_y: 220, width: 90, height: 90, rotation: 0 }],
  ["M4", standard, :square, 4, :available, { pos_x: 260, pos_y: 220, width: 90, height: 90, rotation: 0 }],
  ["M5", standard, :square, 4, :reserved,  { pos_x: 180, pos_y: 380, width: 110, height: 110, rotation: 0 }],
  # Main Dining Floor (round tables)
  ["M6", vip,      :round,   4, :available, { pos_x: 420, pos_y: 150, radius: 50, rotation: 0 }],
  ["M7", vip,      :round,   4, :occupied,  { pos_x: 420, pos_y: 300, radius: 50, rotation: 0 }],

  # Rooftop Terrace (rectangle tables)
  ["R1", standard, :rectangle, 6, :available, { pos_x: 150, pos_y: 100, width: 180, height: 80, rotation: 0 }],
  ["R2", standard, :rectangle, 6, :occupied,  { pos_x: 150, pos_y: 250, width: 180, height: 80, rotation: 0 }],
  ["R3", vip,      :rectangle, 8, :available, { pos_x: 150, pos_y: 400, width: 220, height: 90, rotation: 0 }],
  ["R4", vip,      :round,     4, :reserved,  { pos_x: 420, pos_y: 180, radius: 55, rotation: 0 }],

  # Private Lounge (booth / rectangle tables)
  ["P1", booth, :rectangle, 6, :occupied,  { pos_x: 120, pos_y: 120, width: 160, height: 80, rotation: 0 }],
  ["P2", booth, :rectangle, 6, :out_of_service, { pos_x: 120, pos_y: 280, width: 160, height: 80, rotation: 0 }],
  ["P3", booth, :rectangle, 8, :available, { pos_x: 120, pos_y: 440, width: 200, height: 90, rotation: 0 }]
]

tables.each do |(table_number, table_type, shape, capacity, status, layout)|
  area = table_number.start_with?("M") ? main_floor
       : table_number.start_with?("R") ? rooftop
       : private_lounge

  Table.find_or_create_by!(table_number: table_number, area: area) do |t|
    t.table_type = table_type
    t.shape = shape
    t.capacity = capacity
    t.status = status
    t.pos_x = layout[:pos_x]
    t.pos_y = layout[:pos_y]
    t.width = layout[:width]
    t.height = layout[:height]
    t.radius = layout[:radius]
    t.rotation = layout[:rotation]
  end
  puts "Table: #{table_number} (#{area.name})"
end

puts "Seeding complete."
