class Table < ApplicationRecord
  belongs_to :table_type

  enum :status {
    available: 0,
    occupied: 1,
    reserved: 2,
    out_of_service: 3
  }

  validate :capacity, presence: true
end
