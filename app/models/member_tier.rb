class MemberTier < ApplicationRecord
  has_many :user, dependent: :destroy


  validates :discount, presence: true
  validates :active_price, presence: true
end
