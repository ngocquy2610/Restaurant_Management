class Kitchen::DashboardsController < Kitchen::BaseController
  def index
    authorize LowStockRequest, :index?

    @my_requests = policy_scope(LowStockRequest).recent.includes(:ingredient)
    @my_reports  = policy_scope(WasteReport).recent.includes(:ingredient)
  end
end
