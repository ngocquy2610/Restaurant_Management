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
    user.admin? || user.receptionist?
  end

  def destroy?
    user.admin?
  end
end