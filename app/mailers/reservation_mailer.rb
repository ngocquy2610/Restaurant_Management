class ReservationMailer < ApplicationMailer
  default from: ENV.fetch("GMAIL_USERNAME")

  def confirmation(reservation)
    @reservation = reservation
    @user = reservation.user
    @table = reservation.table

    mail(
      to: @user.email,
      subject: "Reservation Table Successfully"
    )
  end
end