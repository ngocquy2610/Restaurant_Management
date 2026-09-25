class Admin::ReservationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_reservation, only: %i[ update_status assign_table change_table ]

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
      if @reservation.user_id.present?
        notify_user(
          recipient: @reservation.user,
          title: "Reservation confirmed",
          body: "Your reservation for #{@reservation.reservation_date.strftime('%d/%m')} at #{@reservation.reservation_time.strftime('%H:%M')} is confirmed — Table #{@reservation.table.table_number}."
        )
      end
      redirect_to admin_reservations_path,
                  notice: "Reservation for #{@reservation.guest_name} was updated to #{@reservation.status.humanize}."
    else
      redirect_to admin_reservations_path, alert: @reservation.errors.full_messages.to_sentence
    end
  end

  def assign_table
    authorize @reservation, :update_status?
    old_table = @reservation.table
    if @reservation.update(table: set_table, status: :approved)
      old_table&.refresh_status_from_reservations! if old_table != @reservation.table
      redirect_to admin_reservations_path,
                  notice: "Assigned Table #{@reservation.table.table_number} to #{@reservation.guest_name}."
    else
      redirect_to admin_reservations_path, alert: @reservation.errors.full_messages.to_sentence
    end
  end

  def change_table
    authorize @reservation, :update_status?
    old_table = @reservation.table
    if @reservation.update(table: set_table)
      old_table&.refresh_status_from_reservations! if old_table != @reservation.table
      redirect_to admin_reservations_path,
                  notice: "Moved #{@reservation.guest_name} to Table #{@reservation.table.table_number}."
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

  def set_table
    Table.find(params[:table_id])
  end
end
