class Inventory::StockTransactionsController < Inventory::BaseController
  def index
    authorize StockTransaction, :index?
    scope = policy_scope(StockTransaction).recent.includes(:ingredient, :user)
    scope = scope.by_ingredient(params[:ingredient_id])
    scope = scope.by_type(params[:transaction_type])
    scope = scope.between(params[:from].presence, params[:to].presence) if valid_date?(params[:from]) && valid_date?(params[:to])
    @transactions = scope.page(params[:page]).per(15)
    @ingredients  = policy_scope(Ingredient).order(:name)
  end

  def show
    @stock_transaction = StockTransaction.find(params.expect(:id))
    authorize @stock_transaction
  end

  private

  def valid_date?(value)
    return true if value.blank?
    !Time.zone.parse(value).nil?
  rescue ArgumentError, TypeError
    false
  end
end
