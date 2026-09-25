class CustomerQueue < ApplicationRecord
  belongs_to :user,  optional: true
  belongs_to :table, optional: true

  enum :status, { waiting: 0, seated: 1, cancelled: 2 }, default: :waiting

  scope :waiting, -> { where(status: :waiting).order(:created_at) }

  validates :guest_name,  presence: true
  validates :guest_phone, format: { with: /\A\d{9,11}\z/ }, presence: true

  def hold_table!(table)
    update!(status: :seated, table: table)
  end

  def cancel!
    update!(status: :cancelled)
  end
end
