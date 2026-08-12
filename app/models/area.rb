class Area < ApplicationRecord
  has_many :tables, dependent: :nullify

  validates :name, presence: true

  enum :area_type, {
    indoor: 0,
    outdoor: 1
  }, presence: true

  validates :floor_level, presence: true
end
