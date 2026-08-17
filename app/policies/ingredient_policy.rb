class IngredientPolicy < ApplicationPolicy
  def index?
    user.admin? || user.kitchen_staff? || user.inventory_manager?
  end

  def show?
    index?
  end

  def create?
    user.admin? || user.inventory_manager?
  end

  def update?
    user.admin? || user.inventory_manager?
  end

  def destroy?
    user.admin?
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end