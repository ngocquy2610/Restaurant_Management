class Inventory::WasteReportsController < Inventory::BaseController
  def index
    authorize WasteReport, :index?
    @waste_reports = policy_scope(WasteReport)
                     .by_status(params[:status])
                     .recent
                     .includes(:ingredient, :user)
  end

  def show
    @waste_report = WasteReport.find(params.expect(:id))
    authorize @waste_report
  end

  def verify
    @waste_report = WasteReport.find(params.expect(:id))
    authorize @waste_report, :verify?

    decision = params.require(:waste_report).require(:status)
    verified = params[:waste_report][:verified_quantity].presence
    note     = params[:waste_report][:review_note].presence
    create_restock_task = ActiveModel::Type::Boolean.new.cast(params[:waste_report][:create_restock_task])

    @waste_report.review!(current_user, decision,
                          verified_quantity: verified,
                          note: note,
                          create_restock_task: create_restock_task)

    notify_user(
      recipient: @waste_report.user,
      title: "Waste report #{decision}",
      body: "Your waste report for #{@waste_report.ingredient.name} was #{decision}." \
            "#{note.present? ? " Reason: #{note}" : ""}"
    ) if @waste_report.user

    redirect_to inventory_waste_report_path(@waste_report), notice: "Waste report #{decision}."
  rescue ActiveRecord::RecordInvalid, ArgumentError, StockService::Error => e
    redirect_to inventory_waste_report_path(@waste_report), alert: e.message
  end
end
