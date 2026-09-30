class Inventory::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :require_inventory_access!

  private

  def require_inventory_access!
    return if current_user.admin? || current_user.inventory_manager?

    raise Pundit::NotAuthorizedError
  end
end
