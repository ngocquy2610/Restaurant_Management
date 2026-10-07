class Inventory::RestockTasksController < Inventory::BaseController
  before_action :set_restock_task, only: %i[show refill complete]

  def index
    authorize RestockTask, :index?
    @restock_tasks = policy_scope(RestockTask)
                     .by_status(params[:status])
                     .recent
                     .includes(:ingredient)
                     .page(params[:page])
                     .per(10)
  end

  def show
    authorize @restock_task
  end

  def refill
    authorize @restock_task, :refill?
    if @restock_task.completed?
      redirect_to inventory_restock_task_path(@restock_task), alert: "Task already completed."
    end
  end

  def complete
    authorize @restock_task, :complete?

    if @restock_task.completed?
      return redirect_to inventory_restock_task_path(@restock_task), alert: "Task already completed."
    end

    received = params.dig(:restock_task, :received_quantity)
    if received.blank? || received.to_d <= 0
      flash.now[:alert] = "Received quantity must be greater than 0."
      return render :refill, status: :unprocessable_content
    end

    ActiveRecord::Base.transaction do
      @restock_task.update!(
        status:            :completed,
        received_quantity: received.to_d,
        supplier:          params.dig(:restock_task, :supplier),
        note:              params.dig(:restock_task, :note),
        completed_at:      Time.current
      )

      StockService.restock(
        ingredient: @restock_task.ingredient,
        quantity:   received.to_d,
        user:       current_user,
        reason:     params.dig(:restock_task, :note).presence || "Restock task ##{@restock_task.id}",
        reference:  "restock_task:#{@restock_task.id}"
      )
    end

    notify_role(:inventory_manager,
                title: "Restock completed",
                body: "#{@restock_task.ingredient.name}: received #{received}.",
                exclude: current_user)

    redirect_to inventory_restock_task_path(@restock_task),
                notice: "Restock completed and stock updated."
  rescue StockService::Error => e
    flash.now[:alert] = e.message
    render :refill, status: :unprocessable_content
  end

  private

  def set_restock_task
    @restock_task = RestockTask.find(params.expect(:id))
  end
end
