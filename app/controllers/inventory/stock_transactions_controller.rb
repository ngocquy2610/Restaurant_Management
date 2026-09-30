class Inventory::StockTransactionsController < Inventory::BaseController
  def index
    authorize StockTransaction, :index?
    @transactions = policy_scope(StockTransaction).recent.includes(:ingredient, :user)
  end

  def show
    @stock_transaction = StockTransaction.find(params.expect(:id))
    authorize @stock_transaction
  end
end
