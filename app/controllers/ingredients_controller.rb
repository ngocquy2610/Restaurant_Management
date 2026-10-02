class IngredientsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_ingredient, only: %i[show edit update destroy deactivate reactivate]

  # GET /ingredients or /ingredients.json
  def index
    authorize Ingredient, :index?
    @ingredients = policy_scope(Ingredient)
                  .active
                  .search(params[:q])
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
    @ingredient = Ingredient.new(ingredient_params)
    authorize @ingredient

    if @ingredient.save
      notify_user(
        recipient: current_user,
        title: "Ingredient created",
        body: "The ingredient #{@ingredient.name} has been created."
      )
      redirect_to ingredients_path, notice: "Ingredient was successfully created."
    else
      render "ingredients/new", status: :unprocessable_content
    end
  end

  # PATCH/PUT /ingredients/1 or /ingredients/1.json
  def update
    authorize @ingredient
    if @ingredient.update(ingredient_params)
      notify_user(
        recipient: current_user,
        title: "Ingredient updated",
        body: "The ingredient #{@ingredient.name} has been updated."
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
      body: "The ingredient #{@ingredient.name} has been destroyed."
    )
    redirect_to ingredients_path, notice: "Ingredient was successfully destroyed."
  end

  def deactivate
    authorize @ingredient, :deactivate?
    @ingredient.deactivate!
    notify_user(recipient: current_user,
                title: "Ingredient deactivated",
                body: "#{@ingredient.name} was deactivated.")
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

    # Only allow a list of trusted parameters through.
    def ingredient_params
      params.require(:ingredient).permit(:name, :unit, :category, :unit_cost, :current_quantity, :low_stock_threshold)
    end
end
