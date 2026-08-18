class RecipeItemPolicy < ApplicationPolicy
  def index?
    user.admin? || user.kitchen_staff?
  end

  def show?
    index?
  end

  def create?
    user.admin?
  end

  def update?
    user.admin?
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