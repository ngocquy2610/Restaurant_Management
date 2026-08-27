class Reservation < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :table

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

  # Reservation statuses that keep a table held/reserved. Any other (terminal)
  # status frees the table back to available.
  ACTIVE_STATUSES = %i[pending approved checked_in].freeze

  # Keep the table's own status in sync: pending/approved/checked_in hold the
  # table as reserved, while rejected/cancelled/completed release it.
  after_create  :sync_table_status
  after_update  :sync_table_status, if: -> { saved_change_to_status? || saved_change_to_table_id? }
  after_destroy :sync_table_status

  # A table can only be held by one active reservation at a time.
  validate :table_must_not_be_double_booked
  # Out of service / occupied tables cannot be booked.
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

    # Only enforced when the table is being (re)assigned. An existing reservation
    # must not be blocked just because its own check-in put the table into the
    # occupied state (e.g. completing/cancelling it frees the table again).
    return unless new_record? || table_id_changed?

    if table.occupied? || table.out_of_service?
      errors.add(:table, "is not currently bookable")
    end
  end
end
