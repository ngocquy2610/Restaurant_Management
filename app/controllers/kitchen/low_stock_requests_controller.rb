class Kitchen::LowStockRequestsController < Kitchen::BaseController
  def index
    authorize LowStockRequest, :index?
    @low_stock_requests = policy_scope(LowStockRequest).recent.includes(:ingredient)
  end

  def show
    @low_stock_request = LowStockRequest.find(params.expect(:id))
    authorize @low_stock_request
  end

  def new
    @low_stock_request = LowStockRequest.new
    authorize @low_stock_request
    @ingredients = Ingredient.order(:name)
  end

  def create
    @low_stock_request = LowStockRequest.new(low_stock_request_params.merge(user: current_user))
    authorize @low_stock_request

    if @low_stock_request.save
      notify_role(
        :inventory_manager,
        title: "Low stock request",
        body: "#{current_user.full_name} requested more #{@low_stock_request.ingredient.name}."
      )
      redirect_to kitchen_low_stock_requests_path,
                  notice: "Request sent to the inventory manager."
    else
      @ingredients = Ingredient.order(:name)
      render :new, status: :unprocessable_content
    end
  end

  private

  def low_stock_request_params
    params.require(:low_stock_request).permit(:ingredient_id, :note, :urgency)
  end
end
