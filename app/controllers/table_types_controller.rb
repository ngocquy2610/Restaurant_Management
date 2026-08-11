class TableTypesController < ApplicationController
  before_action :set_table_type, only: %i[ show edit update destroy ]

  # GET /table_types or /table_types.json
  def index
    @table_types = TableType.all
  end

  # GET /table_types/1 or /table_types/1.json
  def show
  end

  # GET /table_types/new
  def new
    @table_type = TableType.new
  end

  # GET /table_types/1/edit
  def edit
  end

  # POST /table_types or /table_types.json
  def create
    @table_type = TableType.new(table_type_params)

    respond_to do |format|
      if @table_type.save
        format.html { redirect_to @table_type, notice: "Table type was successfully created." }
        format.json { render :show, status: :created, location: @table_type }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @table_type.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /table_types/1 or /table_types/1.json
  def update
    respond_to do |format|
      if @table_type.update(table_type_params)
        format.html { redirect_to @table_type, notice: "Table type was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @table_type }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @table_type.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /table_types/1 or /table_types/1.json
  def destroy
    @table_type.destroy!

    respond_to do |format|
      format.html { redirect_to table_types_path, notice: "Table type was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_table_type
      @table_type = TableType.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def table_type_params
      params.require(:table_type).permit(:type, :price_add_on)
    end
end
