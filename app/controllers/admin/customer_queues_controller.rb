class Admin::CustomerQueuesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_customer_queue, only: %i[cancel seat destroy]

  def index
    authorize CustomerQueue, :index?
    @customer_queue = CustomerQueue.new
    @queues = CustomerQueue.waiting
    @available_tables = Table.available.order(:table_number)
  end

  def create
    authorize CustomerQueue, :create?
    CustomerQueueManager.enqueue_walk_in!(customer_queue_params, staff: current_user)
    redirect_to admin_customer_queues_path, notice: "Walk-in added to the queue."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to admin_customer_queues_path, alert: e.record.errors.full_messages.to_sentence
  end

  def seat
    authorize @customer_queue, :seat?
    table = Table.find(params[:table_id])
    CustomerQueueManager.seat!(@customer_queue, table)
    notify_role(:receptionist, title: "Walk-in seated",
                body: "#{@customer_queue.guest_name} seated at Table #{table.table_number}.")
    redirect_to admin_customer_queues_path,
                notice: "Seated #{@customer_queue.guest_name} at Table #{table.table_number}."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to admin_customer_queues_path, alert: e.record.errors.full_messages.to_sentence
  end

  def cancel
    authorize @customer_queue, :cancel?
    @customer_queue.cancel!
    redirect_to admin_customer_queues_path, notice: "#{@customer_queue.guest_name} was removed from the queue."
  end

  def destroy
    @customer_queue.destroy!
    redirect_to admin_customer_queues_path, notice: "Queue entry removed."
  end

  private
  def set_customer_queue
    @customer_queue = CustomerQueue.find(params.expect(:id))
  end

  def customer_queue_params
    params.require(:customer_queue).permit(:guest_name, :guest_phone, :note)
  end
end
