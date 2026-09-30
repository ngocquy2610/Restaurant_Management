class Inventory::DashboardsController < Inventory::BaseController
  def index
    authorize Ingredient, :index?

    @low_stock_ingredients = policy_scope(Ingredient).needs_restock.order(:name)
    @open_restock_tasks    = policy_scope(RestockTask).open.recent.includes(:ingredient)
    @pending_requests      = policy_scope(LowStockRequest).pending.recent.includes(:ingredient, :user)
    @pending_waste_reports = policy_scope(WasteReport).pending.recent.includes(:ingredient, :user)
  end
end
