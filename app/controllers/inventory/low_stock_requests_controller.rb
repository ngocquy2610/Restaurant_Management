class Inventory::LowStockRequestsController < Inventory::BaseController
  def index
    authorize LowStockRequest, :index?
    @low_stock_requests = policy_scope(LowStockRequest).recent.includes(:ingredient, :user)
  end

  def show
    @low_stock_request = LowStockRequest.find(params.expect(:id))
    authorize @low_stock_request
  end

  def review
    @low_stock_request = LowStockRequest.find(params.expect(:id))
    authorize @low_stock_request, :review?

    decision = params.require(:low_stock_request).require(:status)

    begin
      @low_stock_request.review!(current_user, decision)
    rescue ArgumentError
      return redirect_to inventory_low_stock_request_path(@low_stock_request),
                         alert: "Invalid decision."
    end

    notify_user(
      recipient: @low_stock_request.user,
      title: "Low stock request #{decision}",
      body: "Your request for #{@low_stock_request.ingredient.name} was #{decision}."
    )
    redirect_to inventory_low_stock_request_path(@low_stock_request),
                notice: "Request #{decision}."
  end
end
