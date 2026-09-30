class RestockTaskPolicy < ApplicationPolicy
  def index?   = user.present? && (user.admin? || user.inventory_manager? || user.kitchen_staff?)
  def show?    = index?
  def advance? = user.present? && (user.admin? || user.inventory_manager?)

  class Scope < Scope
    def resolve
      return scope.all if user.admin? || user.inventory_manager? || user.kitchen_staff?
      scope.none
    end
  end
end
