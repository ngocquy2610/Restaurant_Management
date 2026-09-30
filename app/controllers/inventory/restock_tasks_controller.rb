class Inventory::RestockTasksController < Inventory::BaseController
  def index
    authorize RestockTask, :index?
    @restock_tasks = policy_scope(RestockTask).recent.includes(:ingredient)
  end

  def show
    @restock_task = RestockTask.find(params.expect(:id))
    authorize @restock_task
  end

  def advance
    @restock_task = RestockTask.find(params.expect(:id))
    authorize @restock_task, :advance?

    @restock_task.complete!
    redirect_to inventory_restock_task_path(@restock_task), notice: "Restock task completed."
  end
end
