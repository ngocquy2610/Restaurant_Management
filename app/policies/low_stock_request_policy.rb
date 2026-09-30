class LowStockRequestPolicy < ApplicationPolicy
  def index?   = user.present? && (user.admin? || user.inventory_manager? || user.kitchen_staff?)
  def show?    = index? && (reviewer? || owner?)
  def create?  = user.present? && (user.kitchen_staff? || user.admin?)
  def review?  = reviewer?
  def update?  = review?
  def destroy? = user.present? && user.admin?

  class Scope < Scope
    def resolve
      return scope.all if user.admin? || user.inventory_manager?
      scope.where(user_id: user.id)
    end
  end

  private

  def owner?    = user.present? && record.user_id == user.id
  def reviewer? = user.present? && (user.admin? || user.inventory_manager?)
end
