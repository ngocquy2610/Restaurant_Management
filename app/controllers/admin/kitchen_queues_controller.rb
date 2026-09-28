class Admin::KitchenQueuesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_item, only: %i[update_status]

  def index
    authorize OrderItem, :kitchen_queue?
    @items = policy_scope(OrderItem).in_kitchen.includes(:food, :food_variant, :order => :table)
  end

  def show
    authorize OrderItem, :kitchen_queue?
    @order = Order.includes(order_items: [:food, :food_variant], table: :table_type).find(params[:id])
    @grouped_recipes = build_recipe_map(@order) # { order_item_id => [recipe_items] }
    @aggregated_ingredients = aggregate_ingredients(@order)
  end

  def update_status
    authorize @item, :update_status?
    target = params.require(:order_item).require(:status)
    # must have order_item and just limit at status

    unless order_item_transition_allowed?(@item.status, target)
      return redirect_to redirect_target_after_update,
                         alert: "Cannot move #{@item.food&.name} from '#{@item.status}' to '#{target}'."
    end

    @item.update!(status: target)

    notify_role(:waiter,
      title: "Order ready",
      body: "#{@item.quantity}x #{@item.food&.name} for Table #{@item.order&.table&.table_number} is ready to serve.") if @item.ready?

    redirect_to redirect_target_after_update,
                notice: "Table #{@item.order&.table&.table_number}: #{@item.food&.name} → #{target.humanize}."
  rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => e
    redirect_to admin_kitchen_queues_path, alert: e.message
  end

  private

  def set_item
    @item = OrderItem.find(params.expect(:id))
  end

  # Keep the chef on the order detail page when the action comes from there,
  # otherwise fall back to the queue board.
  def redirect_target_after_update
    if params[:kitchen_queue_id].present?
      admin_kitchen_queue_path(params[:kitchen_queue_id])
    else
      admin_kitchen_queues_path
    end
  end

  # Variant recipe wins; fall back to the base (no-variant) recipe.
  def resolve_recipe_items(item)
    if item.food_variant_id.present?
      variant_items = RecipeItem.includes(:ingredient)
                                .where(food_id: item.food_id, food_variant_id: item.food_variant_id)
      return variant_items if variant_items.any?
    end
    RecipeItem.includes(:ingredient).where(food_id: item.food_id, food_variant_id: nil)
  end

  def build_recipe_map(order)
    order.order_items.each_with_object({}) do |item, hash|
      hash[item.id] = resolve_recipe_items(item).to_a
    end
  end

  def aggregate_ingredients(order)
    totals = Hash.new { |h, k| h[k] = { ingredient: nil, total_qty: 0.to_d, unit: nil } }

    build_recipe_map(order).each do |order_item_id, recipe_items|
      quantity = order.order_items.find { |i| i.id == order_item_id }&.quantity.to_i
      recipe_items.each do |ri|
        key = ri.ingredient_id
        totals[key][:ingredient] ||= ri.ingredient
        totals[key][:unit] ||= ri.ingredient&.unit
        totals[key][:total_qty] += ri.quantity_required.to_d * quantity
      end
    end

    totals.values.map do |entry|
      ingredient = entry[:ingredient]
      stock = ingredient&.current_stock.to_d
      threshold = ingredient&.low_stock_threshold.to_d
      entry.merge(low_stock: ingredient.present? && stock <= threshold)
    end.sort_by { |e| e[:ingredient]&.name.to_s }
  end

  def order_item_transition_allowed?(current_status, target)
    OrdersHelper::ORDER_ITEM_TRANSITIONS.fetch(current_status.to_s, []).include?(target.to_sym)
  end
end
