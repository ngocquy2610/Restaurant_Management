class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :validatable, :jwt_authenticatable,
    jwt_revocation_strategy: JwtDenylist

  after_update :calculate_member_tier!, if: :saved_change_to_year_spend?

  before_validation :set_jti, on: :create

  belongs_to :member_tier, optional: true

  has_one_attached :avatar

  validate :avatar_type_and_size

  enum :role, {
    admin: 0,
    inventory_manager: 1,
    kitchen_staff: 2,
    receptionist: 3,
    waiter: 4,
    customer: 5
  }, default: :customer

  validates :full_name, presence: true
  validates :email, presence: true, uniqueness: true,
                     format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, format: { with: /\A\d{9,11}\z/ }, presence: true, uniqueness: true

  validates :member_tier_id, numericality: { only_integer: true }, allow_nil: true
  validates :year_spend, numericality: { greater_than_or_equal_to: 0 }

  attribute :year_spend, default: 0

  def current_member_tier
    member_tier || MemberTier.order(:active_price, :id).first
  end

  def next_member_tier
    current = current_member_tier
    return nil if current.nil?

    MemberTier.where("active_price > ?", current.active_price)
              .order(:active_price, :id)
              .first
  end

  def amount_to_next_member_tier
    return nil if next_member_tier.nil?

    [next_member_tier.active_price - (year_spend || 0), 0].max
  end

  private

  def set_jti
    self.jti ||= SecureRandom.uuid
  end

  def avatar_type_and_size
    return unless avatar.attached?

    unless avatar.content_type.in?(%w[image/png image/jpeg image/webp])
      errors.add(:avatar, "must be a PNG, JPEG, or WEBP")
    end

    if avatar.byte_size > 5.megabytes
      errors.add(:avatar, "must be under 5MB")
    end
  end

  def calculate_member_tier!
    spend = year_spend.to_i

    new_tier = MemberTier.where("active_price <= ?", spend)
                        .order(active_price: :desc)
                        .first

    update_column(:member_tier_id, new_tier&.id) if new_tier&.id != member_tier_id
  end
end
