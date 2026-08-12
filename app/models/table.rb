class Table < ApplicationRecord
  belongs_to :area
  belongs_to :table_type

  enum :shape, { square: 0, round: 1, rectangle: 2 }
  enum :status, { available: 0, occupied: 1, reserved: 2, out_of_service: 3 }

  validates :table_number, presence: true, uniqueness: { scope: :area_id }
  validates :capacity, numericality: { only_integer: true, greater_than: 0 }, presence: true

  validates :radius, presence: true, numericality: { greater_than: 0 }, if: :round?, allow_nil: true
  validates :width, :height, presence: true, numericality: { greater_than: 0 }, unless: :round?, allow_nil: true
end
