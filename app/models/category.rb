class Category < ApplicationRecord
  has_many :foods, dependent: :destroy

  validates :name, presence: true, uniqueness: { case_sensitive: false }
end
