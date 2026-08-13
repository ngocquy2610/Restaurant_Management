class TableType < ApplicationRecord
  self.inheritance_column = nil

  has_many :table, dependent: :destroy
  validates :type, presence: true
  validates :price_add_on, presence: true
end
