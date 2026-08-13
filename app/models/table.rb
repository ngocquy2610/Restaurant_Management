class Table < ApplicationRecord
  belongs_to :area
  belongs_to :table_type

  enum :shape, { square: 0, round: 1, rectangle: 2 }
  enum :status, { available: 0, occupied: 1, reserved: 2, out_of_service: 3 }

  # Seating capacities admins are allowed to pick, and which table shapes
  # support each of them.
  ALLOWED_CAPACITIES = [2, 4, 6, 8, 10].freeze
  SHAPE_CAPACITIES = {
    "square" => [2, 4],
    "round" => [4, 6],
    "rectangle" => [6, 8, 10]
  }.freeze

  validates :table_number, presence: true, uniqueness: { scope: :area_id }
  validates :capacity, presence: true,
                       inclusion: { in: ALLOWED_CAPACITIES, message: "must be 2, 4, 6, 8, or 10 guests" }
  validates :shape, presence: true
  validate :capacity_matches_shape

  validates :radius, presence: true, numericality: { greater_than: 0 }, if: :round?, allow_nil: true
  validates :width, :height, presence: true, numericality: { greater_than: 0 }, unless: :round?, allow_nil: true

  validates :pos_x, :pos_y, :radius,
            numericality: true, allow_nil: true

  before_validation :generate_table_number, on: :create, if: -> { table_number.blank? }

  private

  def generate_table_number
    return if area.blank? || table_type.blank?

    prefix = "#{area.name.to_s.first}#{table_type.type.to_s.first}"
    return if prefix.blank? || prefix.length < 2

    index = 1
    index += 1 while Table.exists?(area_id: area.id, table_number: "#{prefix}#{index}")

    self.table_number = "#{prefix}#{index}"
  end

  def capacity_matches_shape
    return if capacity.blank? || shape.blank?

    allowed = SHAPE_CAPACITIES[shape]
    errors.add(:capacity, "cannot be #{capacity} guests for a #{shape} table (allowed: #{allowed.join(', ')} guests)") if allowed && !allowed.include?(capacity)
  end
end
