class DashboardsController < ApplicationController
  before_action :authenticate_user!

  def index
    authorize User, :index? #Fine the user policy, check the index policy
    render 'admin/dashboards/index'
  end
end