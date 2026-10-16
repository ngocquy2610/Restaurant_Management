class RecipeItemsController < ApplicationController
  before_action :set_recipe_item, only: %i[ show edit update destroy ]

  # GET /recipe_items or /recipe_items.json
  def index
    authorize RecipeItem, :index?
    @recipe_items = RecipeItem.includes(:food, :food_variant, :ingredient).order(:id)
  end

  # GET /recipe_items/1 or /recipe_items/1.json
  def show
    authorize @recipe_item
  end

  # GET /recipe_items/new
  def new
    @recipe_item = RecipeItem.new(food_id: params[:food_id])
    authorize @recipe_item
    load_form_options
  end

  # GET /recipe_items/1/edit
  def edit
    authorize @recipe_item
    load_form_options
  end

  # POST /recipe_items or /recipe_items.json
  def create
    @recipe_item = RecipeItem.new(recipe_item_params)
    authorize @recipe_item

    if @recipe_item.save
      notify_user(
        recipient: current_user,
        title: "Recipe item created",
        body: "#{recipe_label(@recipe_item)} has been added.",
        redirect_url: food_path(@recipe_item.food)
      )
      redirect_to food_path(@recipe_item.food), notice: "Recipe item was successfully created."
    else
      load_form_options
      render "recipe_items/new", status: :unprocessable_content
    end
  end

  # PATCH/PUT /recipe_items/1 or /recipe_items/1.json
  def update
    authorize @recipe_item
    if @recipe_item.update(recipe_item_params)
      notify_user(
        recipient: current_user,
        title: "Recipe item updated",
        body: "#{recipe_label(@recipe_item)} has been updated.",
        redirect_url: food_path(@recipe_item.food)
      )
      redirect_to food_path(@recipe_item.food), notice: "Recipe item was successfully updated."
    else
      load_form_options
      render "recipe_items/edit", status: :unprocessable_content
    end
  end

  # DELETE /recipe_items/1 or /recipe_items/1.json
  def destroy
    authorize @recipe_item
    food  = @recipe_item.food
    label = recipe_label(@recipe_item)
    @recipe_item.destroy!
    notify_user(
      recipient: current_user,
      title: "Recipe item destroyed",
      body: "#{label} has been removed.",
      redirect_url: food_path(food)
    )
    redirect_to food_path(food), notice: "Recipe item was successfully destroyed.", status: :see_other
  end

  private

    def recipe_label(item) = "#{item.ingredient&.name} in #{item.food&.name}"

    def load_form_options
      @foods = Food.order(:name)
      @ingredients = Ingredient.order(:name)
      @food_variants = FoodVariant.includes(:food).order(:name)
    end

    def label(ri) = "#{ri.ingredient&.name} in #{ri.food&.name}"

    # Use callbacks to share common setup or constraints between actions.
    def set_recipe_item
      @recipe_item = RecipeItem.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def recipe_item_params
      params.require(:recipe_item).permit(:food_id, :food_variant_id, :ingredient_id, :quantity_required)
    end
end
