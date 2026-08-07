class User < ApplicationRecord
    devise :database_authenticatable, :registerable,
      :recoverable, :rememberable, :validatable, :jwt_authenticatable,
      jwt_revocation_strategy: JwtDenylist

  before_validation :set_jti, on: :create

  enum :role, {
    admin: 0,
    inventory_manager: 1,
    kitchen_staff: 2,
    receptionist: 3,
    waiter: 4,
    customer: 5
  }

  validates :full_name, presence: true
  validates :email, presence: true, uniqueness: true,
                     format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, format: { with: /\A\d{9,11}\z/ }, presence: true, uniqueness: true

  private

  def set_jti
    self.jti ||= SecureRandom.uuid
  end
end
