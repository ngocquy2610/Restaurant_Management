class Kitchen::WasteReportsController < Kitchen::BaseController
  def index
    authorize WasteReport, :index?
    @waste_reports = policy_scope(WasteReport).recent.includes(:ingredient)
  end

  def show
    @waste_report = WasteReport.find(params.expect(:id))
    authorize @waste_report
  end

  def new
    @waste_report = WasteReport.new
    authorize @waste_report
    @ingredients = Ingredient.order(:name)
  end

  def create
    @waste_report = WasteReport.new(waste_report_params.merge(user: current_user))
    authorize @waste_report

    if @waste_report.save
      notify_role(
        :inventory_manager,
        title: "Waste reported",
        body: "#{current_user.full_name} reported #{@waste_report.quantity} #{@waste_report.ingredient.unit} of #{@waste_report.ingredient.name} wasted."
      )
      redirect_to kitchen_waste_reports_path, notice: "Waste report submitted."
    else
      @ingredients = Ingredient.order(:name)
      render :new, status: :unprocessable_content
    end
  end

  private

  def waste_report_params
    params.require(:waste_report).permit(:ingredient_id, :quantity, :reason)
  end
end
