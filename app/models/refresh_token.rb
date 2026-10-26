class RefreshToken < ApplicationRecord
  belongs_to :user

  validates :token_hash, :expires_at, presence: true

  scope :available, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }

  TTL = 7.days
  
  def self.digest(raw_token)
    Digest::SHA256.hexdigest(raw_token)
  end

  def self.issue!(user:, user_agent: "", device_name: "")
    raw_token = SecureRandom.urlsafe_base64(64)

    record = create!(
      user: user,
      token_hash: digest(raw_token),
      expires_at: TTL.from_now,
      user_agent: user_agent.to_s.first(500),
      device_name: device_name.to_s.first(100)
    )

    [record, raw_token]
  end

  def self.rotate!(raw_token:, user_agent: "")
    transaction do
      token = lock.find_by(token_hash: digest(raw_token))
      next nil unless token&.active?

      unless token.user.active_for_authentication?
        token.update!(revoked_at: Time.current)
        next nil
      end

      token.update!(revoked_at: Time.current)

      replacement, replacement_raw = issue!(
        user: token.user,
        user_agent: user_agent
      )

      [replacement, replacement_raw]
    end
  end

  def active?
    revoked_at.nil? && expires_at > Time.current
  end

  def revoke!
    update!(revoked_at: Time.current)
  end
end