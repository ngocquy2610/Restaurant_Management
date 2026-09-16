class OrderItemPolicy < ApplicationPolicy
  def index?
    staff?
  end

  def show?
    staff?
  end

  def create?
    order_taker?
  end

  def new?
    order_taker?
  end

  def update?
    order_taker?
  end

  def update_status?
    order_taker?
  end

  def destroy?
    order_taker?
  end

  class Scope < Scope
    def resolve
      staff? ? scope.all : scope.none
    end
  end

  private

  def order_taker?
    user.admin? || user.waiter?
  end

  def staff?
    user.admin? || user.waiter? || user.kitchen_staff?
  end
end