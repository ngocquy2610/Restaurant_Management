class AreasController < ApplicationController
  before_action :authenticate_user!

  def index
    authorize Area
    @areas = Area.order(:floor_level, :position)
    @current_area = @areas.find_by(id: params[:area_id]) || @areas.first
    @tables = @current_area&.tables || Table.none
    render "admin/areas/index"
  end

end