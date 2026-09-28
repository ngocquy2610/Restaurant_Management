class OrderItemsController < ApplicationController
  before_action :set_order_item, only: %i[ update_status destroy ]

  # POST /order_items
  # Adds an item to an existing order from the order detail page.
  def create
    @order_item = OrderItem.new(order_item_params.merge(order_id: params[:order_id]))
    authorize @order_item

    if @order_item.save
      notify_role(:kitchen_staff,
        title: "Item added to order",
        body: "#{@order_item.quantity}x #{@order_item.food&.name} for table #{@order_item.order&.table&.table_number}."
      )
      redirect_to @order_item.order, notice: "Item was successfully added."
    else
      @order = @order_item.order
      render "orders/show", status: :unprocessable_entity
    end
  end

  # PATCH /order_items/1/update_status
  def update_status
    authorize @order_item, :update_status?
    target = params.require(:order_item).require(:status)

    # 1. Validate against the general state machine.
    allowed = OrdersHelper::ORDER_ITEM_TRANSITIONS.fetch(@order_item.status.to_s, [])
    unless allowed.include?(target.to_sym)
      return redirect_to @order_item.order,
        alert: "Cannot move #{@order_item.food&.name} from '#{@order_item.status}' to '#{target}'."
    end

    # 2. Waiters may only do pending -> cancelled and ready -> served.
    if current_user.waiter?
      waiter_allowed = OrdersHelper::WAITER_ALLOWED_TRANSITIONS.fetch(@order_item.status.to_s, [])
      unless waiter_allowed.include?(target.to_sym)
        return redirect_to @order_item.order,
          alert: "Waiter can only mark Ready as Served (or cancel a new pending item)."
      end
    end

    if @order_item.update(status: target)
      if @order_item.served?
        notify_role(:kitchen_staff,
          title: "Dish served",
          body: "#{@order_item.quantity}x #{@order_item.food&.name} for table #{@order_item.order&.table&.table_number} has been served.")
      end
      redirect_to @order_item.order, notice: "Table #{@order_item.order&.table&.table_number}: #{@order_item.food&.name} → #{target.humanize}."
    else
      redirect_to @order_item.order, alert: @order_item.errors.full_messages.to_sentence
    end
  end

  # DELETE /order_items/1
  def destroy
    authorize @order_item
    order = @order_item.order
    @order_item.destroy!
    redirect_to order.persisted? ? order : orders_path, notice: "Item was removed.", status: :see_other
  end

  private

    def set_order_item
      @order_item = OrderItem.find(params.expect(:id))
    end

    def order_item_params
      params.require(:order_item).permit(
        :food_id, :food_variant_id, :quantity, :special_note
      )
    end

    def status_params
      params.require(:order_item).permit(:status)
    end
end
