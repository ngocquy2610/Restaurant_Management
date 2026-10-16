class IngredientsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_ingredient, only: %i[show edit update destroy deactivate reactivate]

  # GET /ingredients or /ingredients.json
  def index
    authorize Ingredient, :index?
    @show_inactive = params[:inactive] == "1"
    base = policy_scope(Ingredient)
    base = @show_inactive ? base.archived : base.active
    @ingredients = base.search(params[:q])
                       .by_category(params[:category])
                       .by_status(params[:status])
                       .order(:name)
                       .page(params[:page])
                       .per(10)
  end

  def show
    authorize @ingredient
    @recent_transactions = @ingredient.stock_transactions
                                        .recent
                                        .includes(:user)
                                        .limit(10)
    @open_restock_task = @ingredient.restock_tasks.open.recent.first
  end

  # GET /ingredients/new
  def new
    @ingredient = Ingredient.new
    authorize @ingredient
  end

  # GET /ingredients/1/edit
  def edit
    authorize @ingredient
  end

  # POST /ingredients or /ingredients.json
  def create
    @ingredient = Ingredient.new(create_params)
    authorize @ingredient
    initial = @ingredient.initial_quantity.to_d
    @ingredient.current_quantity = 0

    Ingredient.transaction do
      @ingredient.save!
      if initial.positive?
        StockService.restock(ingredient: @ingredient, quantity: initial,
                             user: current_user, reason: "Opening balance")
      end
      StockService.sync_restock_task!(@ingredient.reload)
    end

    notify_user(
      recipient: current_user,
      title: "Ingredient created",
      body: "The ingredient #{@ingredient.name} has been created.",
      redirect_url: ingredient_path(@ingredient)
    )
    redirect_to ingredients_path, notice: "Ingredient was successfully created."
  rescue ActiveRecord::RecordInvalid
    render "ingredients/new", status: :unprocessable_content
  end

  # PATCH/PUT /ingredients/1 or /ingredients/1.json
  def update
    authorize @ingredient
    if @ingredient.update(update_params)
      StockService.sync_restock_task!(@ingredient)
      notify_user(
        recipient: current_user,
        title: "Ingredient updated",
        body: "The ingredient #{@ingredient.name} has been updated.",
        redirect_url: ingredient_path(@ingredient)
      )
      redirect_to ingredients_path, notice: "Ingredient was successfully updated."
    else
      render "ingredients/edit", status: :unprocessable_content
    end
  end

  # DELETE /ingredients/1 or /ingredients/1.json
  def destroy
    authorize @ingredient
    @ingredient.destroy!
    notify_user(
      recipient: current_user,
      title: "Ingredient destroyed",
      body: "The ingredient #{@ingredient.name} has been destroyed.",
      redirect_url: ingredients_path
    )
    redirect_to ingredients_path, notice: "Ingredient was successfully destroyed."
  end

  def deactivate
    authorize @ingredient, :deactivate?
    @ingredient.deactivate!
    notify_user(recipient: current_user,
                title: "Ingredient deactivated",
                body: "#{@ingredient.name} was deactivated.",
                redirect_url: ingredient_path(@ingredient))
    redirect_to ingredients_path, notice: "Ingredient deactivated.", status: :see_other
  end

  def reactivate
    authorize @ingredient, :reactivate?
    @ingredient.reactivate!
    redirect_to ingredients_path, notice: "Ingredient reactivated.", status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ingredient
      @ingredient = Ingredient.find(params.expect(:id))
    end

    BASE_PARAMS = %i[name unit category unit_cost low_stock_threshold reorder_quantity].freeze

    def create_params
      params.require(:ingredient).permit(*BASE_PARAMS, :initial_quantity)
    end

    def update_params
      params.require(:ingredient).permit(*BASE_PARAMS)
    end
end
