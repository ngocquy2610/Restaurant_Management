class ReservationConfirmationJob < ApplicationJob
  queue_as :default

  def perform(reservation_id)
    reservation = Reservation.find_by(id: reservation_id)
    return if reservation.blank?
    return unless reservation.approved?
    return if reservation.user.blank? || reservation.user.email.blank?

    ReservationMailer.confirmation(reservation).deliver_now
  end
end