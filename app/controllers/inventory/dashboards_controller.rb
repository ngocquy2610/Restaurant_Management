class Inventory::DashboardsController < Inventory::BaseController
  def index
    authorize Ingredient, :index?

    @need_restock = policy_scope(Ingredient).needs_restock.order(:name)
    @open_restock_tasks    = policy_scope(RestockTask).open.recent.includes(:ingredient)
    @pending_requests      = policy_scope(LowStockRequest).pending.recent.includes(:ingredient, :user)
    @pending_waste_reports = policy_scope(WasteReport).pending.recent.includes(:ingredient, :user)

    @summary = {
      total_ingredients: policy_scope(Ingredient).active.count,
      low_stock: policy_scope(Ingredient).active.low_stock.count,
      out_of_stock: policy_scope(Ingredient).active.out_of_stock.count,
      pending_requests: policy_scope(LowStockRequest).pending.count,
      pending_waste_reports: policy_scope(WasteReport).pending.count
    }
  end
end
