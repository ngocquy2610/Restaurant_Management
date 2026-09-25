class CustomerQueuePolicy < ApplicationPolicy
  def index?
    staff?
  end

  def create?
    staff?
  end

  def cancel?
    staff?
  end

  def destroy?
    staff?
  end

  def seat?
    staff?
  end

  private
  def staff?
    user.admin? || user.receptionist?
  end
end
