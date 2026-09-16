class OrderPolicy < ApplicationPolicy
  def index?
    staff?
  end

  def show?
    staff? || record.waiter == user
  end

  def create?
    placer?
  end

  def new?
    placer?
  end

  def update?
    order_taker?
  end

  def edit?
    order_taker?
  end

  def update_status?
    order_taker?
  end

  def destroy?
    user.admin?
  end

  class Scope < Scope
    def resolve
      if user.admin? || user.waiter? || user.kitchen_staff?
        scope.all
      else
        scope.none
      end
    end
  end

  private

  # Waiters and admins take orders for customers; customers may place preorders.
  def placer?
    user.admin? || user.waiter? || user.customer?
  end

  # Waiters and admins can edit / drive an in-service order.
  def order_taker?
    user.admin? || user.waiter?
  end

  # Anyone who works the floor or kitchen may view orders.
  def staff?
    user.admin? || user.waiter? || user.kitchen_staff?
  end
end
