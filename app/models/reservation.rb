class Reservation < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :table

  has_many :orders, dependent: :destroy

  validates :guest_name,        presence: true
  validates :guest_phone,       format: { with: /\A\d{9,11}\z/ }, presence: true
  validates :reservation_date,  presence: true
  validates :reservation_time,  presence: true

  enum :status, {
    pending: 0, approved: 1, rejected: 2,
    checked_in: 3, cancelled: 4, completed: 5
  }, default: 0

  ACTIVE_STATUSES = %i[pending approved checked_in].freeze

  # Mỗi bữa ăn kéo dài 2 tiếng.
  MEAL_DURATION = 2.hours
  # Giờ bắt đầu của các slot đặt chỗ.
  MEAL_START_HOURS = [11, 13, 17, 19, 21].freeze

  after_create  :sync_table_status
  after_update  :sync_table_status, if: -> { saved_change_to_status? || saved_change_to_table_id? }
  after_destroy :sync_table_status

  validate :table_must_not_be_double_booked
  validate :table_must_be_bookable
  validate :reservation_time_must_be_a_meal_slot  # (ko—gie-túi) xem bên dưới

  # ---- Các helper thời gian ----

  # Thời điểm bắt đầu của slot (kết hợp reservation_date + reservation_time).
  def slot_start
    return if reservation_date.blank? || reservation_time.blank?

    Time.zone.local(
      reservation_date.year, reservation_date.month, reservation_date.day,
      reservation_time.hour, reservation_time.min, reservation_time.sec
    )
  end

  # Thời điểm kết thúc slot (bắt đầu + 2h).
  def slot_end
    slot_start && slot_start + MEAL_DURATION
  end

  # Reservation này đang "giữ" bàn tại thời điểm `time` không?
  def holds_table_now?(time = Time.zone.now)
    return false unless ACTIVE_STATUSES.include?(status.to_sym)
    return false unless slot_start

    (slot_start...slot_end).cover?(time)
  end

  # Hàm static: tạo danh sách slot cho một ngày cụ thể.
  def self.meal_slots_for(date)
    return [] if date.blank?
    MEAL_START_HOURS.map { |hour| Time.zone.local(date.year, date.month, date.day, hour) }
  end

  # Hàm static: slot còn trống của một bàn trong một ngày.
  def self.available_slots(table, date, exclude_id: nil)
    return [] if table.blank? || date.blank?
    return [] if table.out_of_service?

    ranges = booked_ranges(table, date, exclude_id: exclude_id)
    meal_slots_for(date).reject do |slot|
      window = slot...(slot + MEAL_DURATION)
      ranges.any? { |r| ranges_overlap?(window, r) }
    end
  end

  private

  def sync_table_status
    table.refresh_status_from_reservations!
  end

  def table_must_not_be_double_booked
    return if table.blank? || slot_start.nil?

    same_day = table.reservations.where(status: ACTIVE_STATUSES, reservation_date: reservation_date)
    same_day = same_day.where.not(id: id) if persisted?

    my_range = slot_start...slot_end
    conflict = same_day.any? { |other| self.class.ranges_overlap?(my_range, other.slot_start...other.slot_end) }

    return unless conflict
    errors.add(:reservation_time,
      "overlaps an existing booking for this table on #{reservation_date}. Please pick another slot.")
  end

  def table_must_be_bookable
    return if table.blank?
    return unless new_record? || table_id_changed?

    if table.out_of_service?
      errors.add(:table, "is not currently bookable")
    elsif table.occupied? && slot_start&.to_date == Date.current
      errors.add(:table, "is currently occupied — please pick another date or slot")
    end
  end

  def reservation_time_must_be_a_meal_slot
    return if reservation_time.blank?
    return if MEAL_START_HOURS.include?(reservation_time.hour) &&
              reservation_time.min == 0 && reservation_time.sec == 0

    errors.add(:reservation_time,
      "must be one of: #{MEAL_START_HOURS.map { |h| '%02d:00' % h }.join(', ')}")
  end

  def self.booked_ranges(table, date, exclude_id:)
    table.reservations
         .where(status: ACTIVE_STATUSES, reservation_date: date)
         .where.not(id: exclude_id)
         .filter_map { |r| (r.slot_start...r.slot_end) if r.slot_start }
  end

  def self.ranges_overlap?(a, b)
    a.begin < b.end && b.begin < a.end
  end
end
