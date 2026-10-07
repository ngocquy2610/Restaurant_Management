class StockTransactionPolicy < ApplicationPolicy
  def index?  = inventory_team?
  def show?   = index?
  def create? = inventory_team?

  class Scope < Scope
    def resolve = (user.admin? || user.inventory_manager?) ? scope.all : scope.none
  end

  private

  def inventory_team? = user.present? && (user.admin? || user.inventory_manager?)
end
