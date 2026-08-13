class TablesController < ApplicationController
  before_action :set_table, only: %i[ show edit update destroy ]

  # GET /tables or /tables.json
  def index
    authorize Table, :index?
    @areas = Area.order(:floor_level, :id)

    # Resolve current area: an explicit, valid area_id wins; otherwise fall back
    # to the first area (e.g. when only /tables is requested).
    @area = if params[:area_id].present?
              @areas.find { |a| a.id == params[:area_id].to_i }
            end
    @area ||= @areas.first

    current_index = @area && @areas.index(@area)
    @prev_area = current_index && current_index.positive? ? @areas[current_index - 1] : nil
    @next_area = current_index && current_index < @areas.size - 1 ? @areas[current_index + 1] : nil

    @tables_payload = @area ? @area.tables.map { |t| table_json(t) } : []

    render "tables/index"
  end

  # GET /tables/1 or /tables/1.json
  def show
    authorize @table
  end

  # GET /tables/new
  def new
    @table = Table.new
    @areas = Area.order(:name)
    @table_types = TableType.order(:type)
    @area_tables = tables_by_area
    authorize @table
    render "admin/tables/new"
  end

  # GET /tables/1/edit
  def edit
    @areas = Area.order(:name)
    @table_types = TableType.order(:type)
    @area_tables = tables_by_area
    authorize @table
    render "admin/tables/edit"
  end

  # POST /tables or /tables.json
  def create
    @table = Table.new(table_params)
    authorize @table

    if @table.save
      redirect_to tables_path, notice: "Table added."
    else
      @areas = Area.order(:name)
      @table_types = TableType.order(:type)
      @area_tables = tables_by_area
      render 'admin/tables/new', status: :unprocessable_entity
    end
  end

  # PATCH/PUT /tables/1 or /tables/1.json
  def update
    authorize @table
    if @table.update(table_params)
      redirect_to tables_path, notice: "Table updated."
    else
      @areas = Area.order(:name)
      @table_types = TableType.order(:type)
      @area_tables = tables_by_area
      render 'admin/tables/edit', status: :unprocessable_entity
    end
  end

  # DELETE /tables/1 or /tables/1.json
  def destroy
    authorize @table
    @table.destroy!

    @areas = Area.order(:floor_level, :id)
    @area = if params[:area_id].present?
              @areas.find { |a| a.id == params[:area_id].to_i }
            end
    @area ||= @areas.first

    redirect_to tables_path(area_id: @area&.id), notice: "Table removed."
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_table
      @table = Table.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def table_params
      params.require(:table).permit(
        :area_id, :table_type_id,
        :table_number, :capacity, :status,
        :shape, :pos_x, :pos_y, :rotation,
        :width, :height, :radius
      )
    end
  
  def table_json(table)
    base = {
      id: table.id,
      table_number: table.table_number,
      shape: table.shape,
      capacity: table.capacity,
      status: table.status,
      pos_x: table.pos_x.to_f,
      pos_y: table.pos_y.to_f,
      rotation: table.rotation.to_i
    }
    table.round? ? base.merge(radius: table.radius.to_f) : base.merge(width: table.width.to_f, height: table.height.to_f)
  end

  # Area id => existing table payloads. The wizard canvas consumes this to
  # render the tables already placed in the selected area as read-only context
  # while the admin positions a new/edited table.
  def tables_by_area
    Area.order(:name).each_with_object({}) do |area, hash|
      hash[area.id] = area.tables.map { |t| table_json(t) }
    end
  end
end
