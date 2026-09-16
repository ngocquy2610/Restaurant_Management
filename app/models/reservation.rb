class Reservation < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :table

  has_many :orders, dependent: :destroy

  validates :guest_name, presence: true
  validates :guest_phone, format: { with: /\A\d{9,11}\z/ }, presence: true

  enum :status, {
    pending: 0,
    approved: 1,
    rejected: 2,
    checked_in: 3,
    cancelled: 4,
    completed: 5
  }, default: 0

  ACTIVE_STATUSES = %i[pending approved checked_in].freeze

  after_create  :sync_table_status
  after_update  :sync_table_status, if: -> { saved_change_to_status? || saved_change_to_table_id? }
  after_destroy :sync_table_status

  validate :table_must_not_be_double_booked
  validate :table_must_be_bookable

  private

  def sync_table_status
    table.refresh_status_from_reservations!
  end

  def table_must_not_be_double_booked
    return if table.blank?

    held_by = table.reservations.where(status: ACTIVE_STATUSES)
    held_by = held_by.where.not(id: id) if persisted?
    errors.add(:table, "is already reserved") if held_by.exists?
  end

  def table_must_be_bookable
    return if table.blank?
    return unless new_record? || table_id_changed?

    if table.occupied? || table.out_of_service?
      errors.add(:table, "is not currently bookable")
    end
  end
end
