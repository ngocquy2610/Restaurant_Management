class RecipeItemsController < ApplicationController
  before_action :set_recipe_item, only: %i[ show edit update destroy ]

  # GET /recipe_items or /recipe_items.json
  def index
    authorize RecipeItem, :index?
    @recipe_items = RecipeItem.all
  end

  # GET /recipe_items/1 or /recipe_items/1.json
  def show
    authorize @recipe_item
  end

  # GET /recipe_items/new
  def new
    @recipe_item = RecipeItem.new
    authorize @recipe_item
  end

  # GET /recipe_items/1/edit
  def edit
    authorize @recipe_item
  end

  # POST /recipe_items or /recipe_items.json
  def create
    @recipe_item = RecipeItem.new(recipe_item_params)
    authorize @recipe_item

    if @recipe_item.save
      redirect_to recipe_items_path, notice: "Recipe item was successfully created."
    else
      render "recipe_items/new", status: :unprocessable_content
    end
  end

  # PATCH/PUT /recipe_items/1 or /recipe_items/1.json
  def update
    authorize @recipe_item
    if @recipe_item.update(recipe_item_params)
      redirect_to recipe_items_path, notice: "Recipe item was successfully updated."
    else
      render "recipe_items/edit", status: :unprocessable_content
    end
  end

  # DELETE /recipe_items/1 or /recipe_items/1.json
  def destroy
    authorize @recipe_item
    @recipe_item.destroy!

    redirect_to recipe_items_path, notice: "Recipe item was successfully destroyed."
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_recipe_item
      @recipe_item = RecipeItem.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def recipe_item_params
      params.require(:recipe_item).permit(:food_id, :food_variant_id, :ingredient_id, :quantity_required)
    end
end
