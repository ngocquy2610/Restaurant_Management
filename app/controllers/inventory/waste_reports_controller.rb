class Inventory::WasteReportsController < Inventory::BaseController
  def index
    authorize WasteReport, :index?
    @waste_reports = policy_scope(WasteReport).recent.includes(:ingredient, :user)
  end

  def show
    @waste_report = WasteReport.find(params.expect(:id))
    authorize @waste_report
  end

  def verify
    @waste_report = WasteReport.find(params.expect(:id))
    authorize @waste_report, :verify?

    decision  = params.require(:waste_report).require(:status)
    verified  = params[:waste_report][:verified_quantity].presence

    unless %w[approved rejected].include?(decision)
      return redirect_to inventory_waste_report_path(@waste_report), alert: "Invalid decision."
    end

    @waste_report.review!(current_user, decision, verified_quantity: verified)
    notify_user(
      recipient: @waste_report.user,
      title: "Waste report #{decision}",
      body: "Your waste report for #{@waste_report.ingredient.name} was #{decision}."
    )
    redirect_to inventory_waste_report_path(@waste_report), notice: "Waste report #{decision}."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to inventory_waste_report_path(@waste_report), alert: e.message
  end
end
