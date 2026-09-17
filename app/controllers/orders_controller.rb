class OrdersController < ApplicationController
  before_action :set_order, only: %i[ show edit update destroy update_status ]

  # GET /orders
  def index
    authorize Order, :index?
    @orders = Order.includes(:table, :waiter).order(created_at: :desc)
  end

  # GET /orders/1
  def show
    authorize @order
    @order_item = @order.order_items.build
    @payment_methods = PaymentMethod.where(active: true).order(:code)
    load_food_data
  end

  # GET /orders/new
  def new
    @order = Order.new
    authorize @order
    @order_items = @order.order_items
    load_food_data(occupied_tables: true)
  end

  # GET /orders/1/edit
  def edit
    authorize @order
    @order_items = @order.order_items
    load_food_data
  end

  # POST /orders
  def create
    @order = Order.new(order_params)
    # Record whoever places the order (a waiter/admin for an on-site order,
    # or the customer themself for a preorder).
    @order.waiter = current_user
    # Initial status is derived from who places the order:
    #   - a waiter/admin takes it on-site -> in service
    #   - a customer pre-orders online    -> preorder
    @order.status = order_status_for(current_user)
    authorize @order

    if @order.save
      notify_role(:kitchen_staff,
        title: "New order at #{@order.table&.table_number}",
        body: "#{@order.waiter&.full_name || 'A waiter'} placed an order for #{@order.order_items.count} item(s)."
      )
      redirect_to @order, notice: "Order was successfully created."
    else
      @order_items = @order.order_items
      load_food_data(occupied_tables: true)
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /orders/1
  def update
    authorize @order
    if @order.update(order_params)
      @order.recalculate_total_price!
      redirect_to @order, notice: "Order was successfully updated.", status: :see_other
    else
      @order_items = @order.order_items
      load_food_data
      render :edit, status: :unprocessable_entity
    end
  end

  # PATCH /orders/1/update_status
  def update_status
    authorize @order, :update_status?
    if order_status_params[:status] == "completed" && !@order.payments.completed.exists?
      redirect_to order_path(@order), alert: "Create and confirm a payment before completing this order."
      return
    end

    if @order.update(order_status_params)
      @order.recalculate_total_price!
      redirect_to @order, notice: "Order status updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  # DELETE /orders/1
  def destroy
    authorize @order
    @order.destroy!
    redirect_to orders_path, notice: "Order was successfully destroyed.", status: :see_other
  end

  private

    def set_order
      @order = Order.find(params.expect(:id))
    end

    def load_food_data(occupied_tables: false)
      @categories = Category.order(:name)
      @foods = Food.includes(:category).order(:name)
      @tables = occupied_tables ? Table.occupied.order(:id) : Table.order(:id)

      @variants_by_food = FoodVariant.includes(:food)
                                      .order(:name)
                                      .group_by(&:food_id)
                                      .transform_values do |variants|
        variants.map { |v| { id: v.id, name: v.name } }
      end
    end

    def order_status_for(user)
      user.present? && user.customer? ? :preorder : :inserve
    end

    def order_params
      params.require(:order).permit(
        :table_id, :status,
        order_items_attributes: [
          :id, :food_id, :food_variant_id, :quantity, :special_note, :_destroy
        ]
      )
    end

    def order_status_params
      params.require(:order).permit(:status)
    end
end
