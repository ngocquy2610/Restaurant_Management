class TablePolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    user.admin?
  end

  def update?
    user.admin? || user.receptionist? && scope.out_of_service!
  end

  def destroy?
    user.admin?
  end
end