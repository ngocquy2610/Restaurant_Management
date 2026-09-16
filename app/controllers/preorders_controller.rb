class PreordersController < ApplicationController
  before_action :set_order, only: %i[ show destroy ]

  # GET /preorders — staff overview of every customer pre-order.
  # Pre-orders now live on the orders table (status = :preorder).
  def index
    authorize Order, :index?
    @orders = Order.includes(:reservation, :table).where(status: :preorder).order(created_at: :desc)
  end

  # GET /preorders/new?reservation_id=1 — the customer-facing ordering screen
  # shown right after they finish booking a table.
  def new
    @order = Order.new(status: :preorder, reservation_id: params[:reservation_id])
    authorize @order, :new?
    load_food_data
  end

  # POST /preorders — creates a new Order record directly (status = :preorder)
  # for the table that was just booked.
  def create
    @order = Order.new(preorder_params)
    @order.status = :preorder
    @order.table = @order.reservation&.table
    @order.waiter = current_user
    authorize @order, :create?

    if @order.save
      notify_role(:kitchen_staff,
        title: "Pre-order received",
        body: "#{@order.reservation&.guest_name} pre-ordered dishes for table #{@order.table&.table_number}."
      )
      redirect_to preorder_path(@order), notice: "Your pre-order was received. See you soon!"
    else
      load_food_data
      render :new, status: :unprocessable_entity
    end
  end

  # GET /preorders/1 — confirmation with the chosen dishes + total.
  def show
    authorize @order, :show?
  end

  # DELETE /preorders/1
  def destroy
    authorize @order, :destroy?
    @order.destroy!
    redirect_to preorders_path, notice: "Pre-order was cancelled.", status: :see_other
  end

  private

    def set_order
      @order = Order.find(params.expect(:id))
    end

    # Foods grouped by category + a variant map for the order-form picker.
    def load_food_data
      @categories = Category.order(:name)
      @foods = Food.includes(:category).order(:name)
      @tables = Table.order(:id)

      @variants_by_food = FoodVariant.includes(:food)
                                      .order(:name)
                                      .group_by(&:food_id)
                                      .transform_values do |variants|
        variants.map { |v| { id: v.id, name: v.name } }
      end
    end

    def preorder_params
      params.require(:order).permit(
        :reservation_id,
        order_items_attributes: [:id, :food_id, :food_variant_id, :quantity, :special_note, :_destroy]
      )
    end
end
