class IngredientsController < ApplicationController
  before_action :set_ingredient, only: %i[ show edit update destroy ]

  # GET /ingredients or /ingredients.json
  def index
    authorize Ingredient, :index?
    @ingredients = Ingredient.all
  end

  # GET /ingredients/1 or /ingredients/1.json
  def show
    authorize @ingredient
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
      redirect_to ingredients_path, notice: "Ingredient was successfully created."
    else
      render "ingredients/new", status: :unprocessable_content
    end
  end

  # PATCH/PUT /ingredients/1 or /ingredients/1.json
  def update
    authorize @ingredient
    if @ingredient.update(ingredient_params)
      redirect_to ingredients_path, notice: "Ingredient was successfully updated."
    else
      render "ingredients/edit", status: :unprocessable_content
    end
  end

  # DELETE /ingredients/1 or /ingredients/1.json
  def destroy
    authorize @ingredient
    @ingredient.destroy!

    redirect_to ingredients_path, notice: "Ingredient was successfully destroyed."
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ingredient
      @ingredient = Ingredient.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def ingredient_params
      params.require(:ingredient).permit(:name, :unit, :unit_cost, :current_stock, :low_stock_threshold)
    end
end
