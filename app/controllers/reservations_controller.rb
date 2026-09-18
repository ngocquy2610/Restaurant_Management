class ReservationsController < ApplicationController
  before_action :set_reservation, only: %i[ show edit update destroy update_status ]

  # GET /reservations or /reservations.json
  def index
    authorize Reservation, :index?
    @reservations = Reservation.all
    @areas = Area.order(:floor_level, :id)

    @area = if params[:area_id].present?
              @areas.find { |a| a.id == params[:area_id].to_i }
            end
    @area ||= @areas.first

    current_index = @area && @areas.index(@area)
    @prev_area = current_index && current_index.positive? ? @areas[current_index - 1] : nil
    @next_area = current_index && current_index < @areas.size - 1 ? @areas[current_index + 1] : nil

    @tables_payload = @area ? @area.tables.map { |t| table_json(t) } : []
  end

  # GET /reservations/1 or /reservations/1.json
  def show
  end

  # GET /reservations/new
  def new
    @reservation = Reservation.new(table_id: params[:table_id])
    @slot_date = params[:date].present? ? Date.parse(params[:date]) : Date.current
    set_schedule
  end

  # GET /reservations/1/edit
  def edit
    @slot_date = @reservation.reservation_date || Date.current
    set_schedule
  end

  # POST /reservations or /reservations.json
  def create
    @reservation = Reservation.new(reservation_params)
    @reservation.user ||= current_user

    if @reservation.save
      notify_role(:receptionist,
        title: "New reservation request",
        body: "#{@reservation.guest_name} requested a table at #{@reservation.reservation_date.strftime('%d/%m')} at #{@reservation.reservation_time.strftime('%H:%M')}. Table #{@reservation.table.table_number}."
      )
      notify_role(:admin,
        title: "New reservation request",
        body: "#{@reservation.guest_name} requested a table at #{@reservation.reservation_date.strftime('%d/%m')} at #{@reservation.reservation_time.strftime('%H:%M')}. Table #{@reservation.table.table_number}."
      )
      # Let the customer pre-order dishes for the table they just booked.
      redirect_to new_reservation_preorder_path(@reservation), notice: "Table booked! Add a pre-order below."
    else
      @slot_date = @reservation.reservation_date || Date.current
      set_schedule
      render "reservations/new", status: :unprocessable_content
    end
  end

  # PATCH/PUT /reservations/1 or /reservations/1.json
  def update
    respond_to do |format|
      if @reservation.update(reservation_params)
        format.html { redirect_to @reservation, notice: "Reservation was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @reservation }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @reservation.errors, status: :unprocessable_content }
      end
    end
  end

  def update_status
    authorize @reservation, :update_status?
    if @reservation.update(status_params)
      notify_user(
        recipient: @reservation.user,
        title: "Reservation notice",
        body: "Your reservation for #{@reservation.reservation_date.strftime('%d/%m')} at #{@reservation.reservation_time.strftime('%H:%M')} has sent successfully - Table #{@reservation.table.table_number}"
      )
      redirect_to @reservation, notice: "Reservation status updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  # DELETE /reservations/1 or /reservations/1.json
  def destroy
    @reservation.destroy!

    respond_to do |format|
      format.html { redirect_to reservations_path, notice: "Reservation was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_reservation
      @reservation = Reservation.find(params.expect(:id))
    end

    # Computes the slot data the (shared) reservation form needs to render the
    # date/2-hour-slot picker: every meal slot for the selected date plus the
    # subset that is still free for the currently selected table.
    def set_schedule
      @all_slots = Reservation.meal_slots_for(@slot_date)
      @available_slots = if @reservation.table
                           Reservation.available_slots(@reservation.table, @slot_date, exclude_id: @reservation.id)
                         else
                           []
                         end
    end

    # Only allow a list of trusted parameters through.
    # Status is excluded here on purpose: it may only be changed by admins /
    # receptionists through the dedicated #update_status action, never through
    # the customer-facing create/edit form.
    def reservation_params
      params.require(:reservation).permit(
        :guest_name, :guest_phone, :note,
        :reservation_date, :reservation_time, :table_id
      )
    end

    # Staff-only status changes (reject / approve / check-in, etc.).
    def status_params
      params.require(:reservation).permit(:status)
    end

  def table_json(table)
    base = {
      id: table.id,
      table_number: table.table_number,
      shape: table.shape,
      capacity: table.capacity,
      status: table.status,
      pos_x: table.pos_x.to_f,
      pos_y: table.pos_y.to_f,
      rotation: table.rotation.to_i
    }
    table.round? ? base.merge(radius: table.radius.to_f) : base.merge(width: table.width.to_f, height: table.height.to_f)
  end
end
