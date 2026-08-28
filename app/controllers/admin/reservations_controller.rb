class Admin::ReservationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_reservation, only: :update_status

  def index
    authorize Reservation, :manage?
    @reservations = policy_scope(Reservation)
                    .order(created_at: :desc)
                    .page(params[:page])
                    .per(5)
  end

  def update_status
    authorize @reservation, :update_status?
    if @reservation.update(status_params)
      redirect_to admin_reservations_path,
                  notice: "Reservation for #{@reservation.guest_name} was updated to #{@reservation.status.humanize}."
    else
      redirect_to admin_reservations_path, alert: @reservation.errors.full_messages.to_sentence
    end
  end

  private

  def set_reservation
    @reservation = Reservation.find(params.expect(:id))
  end

  def status_params
    params.require(:reservation).permit(:status)
  end
end
