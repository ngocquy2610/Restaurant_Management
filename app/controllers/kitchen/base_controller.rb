class Kitchen::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :require_kitchen_access!

  private

  def require_kitchen_access!
    return if current_user.admin? || current_user.kitchen_staff?

    raise Pundit::NotAuthorizedError
  end
end
