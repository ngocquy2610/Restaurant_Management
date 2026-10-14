
class ReservationPolicy < ApplicationPolicy
  EDITABLE = %w[pending approved].freeze
  
  def index?
    true
  end

  def show?
    staff? || owner?
  end

  def create?
    true
  end

  def update?
    staff? ? false : owner? && EDITABLE.include?(record.status)
  end

  def destroy?
    update?
  end

  def update_status?
    staff?
  end

  # Staff-only page to review and confirm all reservations.
  def manage?
    staff?
  end

  def permitted_attributes
    if staff?
      %i[status table_id]
    else
      %i[table_id reservation_date reservation_time]
    end
  end

  class Scope < Scope
    def resolve
      if user.admin? || user.receptionist?
        scope.all
      else
        scope.where(user_id: user.id)
      end
    end
  end

  private

  def owner?
    record.user_id == user.id
  end

  def staff?
    user.admin? || user.receptionist?
  end
end