class MemberTier < ApplicationRecord
  has_many :user, dependent: :destroy

  enum :name, {
    bronze: 0,
    silver: 1,
    gold: 2,
    diamond: 3
  }

  validates :discount, presence: true
  validates :active_price, presence: true
end
