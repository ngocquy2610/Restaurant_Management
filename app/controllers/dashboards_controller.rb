class DashboardsController < ApplicationController
  before_action :authenticate_user!

  def index
    authorize User, :index? #Fine the user policy, check the index policy
    @reservations = Reservation
                    .where.not(status: [:completed, :rejected, :cancelled])
                    .page(params[:page])
                    .per(5)
    render 'admin/dashboards/index'
  end
end