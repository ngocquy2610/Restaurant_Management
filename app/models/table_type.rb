class TableType < ApplicationRecord
  has_many :table
  validates :type, presence: true
  validates :price_add_on, presence: true
end
