class Inventory::StockAdjustmentsController < Inventory::BaseController
  # GET /inventory/stock_adjustments/new(?:ingredient_id=)
  def new
    authorize StockTransaction, :create?
    @ingredients = policy_scope(Ingredient).active.order(:name)
    @selected    = params[:ingredient_id].presence
    @quantities  = quantity_map(@ingredients)
  end

  # POST /inventory/stock_adjustments
  def create
    authorize StockTransaction, :create?

    ingredient = policy_scope(Ingredient).find_by(id: params.dig(:stock_adjustment, :ingredient_id))
    physical   = params.dig(:stock_adjustment, :physical_count)
    reason     = params.dig(:stock_adjustment, :reason)

    # --- validate edge cases trước khi chạm vào service ---
    return render_error("Please select an ingredient.") if ingredient.blank?
    return render_error("Physical count can't be blank.", ingredient) if physical.blank?
    return render_error("Physical count can't be negative.", ingredient) if physical.to_d.negative?

    tx = StockService.adjust(
      ingredient:   ingredient,
      new_quantity: physical.to_d,
      user:         current_user,
      reason:       reason.presence || "Stock count adjustment"
    )

    if tx.nil?
      # Không có chênh lệch → service trả nil, không ghi ledger.
      redirect_to ingredient_path(ingredient), notice: "No difference — stock unchanged."
    else
      notify_role(:inventory_manager,
                  title: "Stock adjusted",
                  body: "#{ingredient.name} set to #{physical} by #{current_user.full_name}.",
                  exclude: current_user)
      redirect_to ingredient_path(ingredient), notice: "Stock adjusted for #{ingredient.name}."
    end
  rescue StockService::Error => e
    render_error(e.message, ingredient)
  end

  private

  # Map ingredient_id => current_quantity (string) để JS hiển thị preview.
  def quantity_map(ingredients)
    ingredients.each_with_object({}) { |i, h| h[i.id] = i.current_quantity.to_d.to_s }
  end

  def render_error(message, ingredient = nil)
    @ingredients    = policy_scope(Ingredient).active.order(:name)
    @quantities     = quantity_map(@ingredients)
    @selected       = params.dig(:stock_adjustment, :ingredient_id)
    @physical_count = params.dig(:stock_adjustment, :physical_count)
    @reason         = params.dig(:stock_adjustment, :reason)
    flash.now[:alert] = message
    render :new, status: :unprocessable_content
  end
end
