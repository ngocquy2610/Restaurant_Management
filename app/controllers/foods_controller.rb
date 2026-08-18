class FoodsController < ApplicationController
  before_action :set_food, only: %i[ show edit update destroy ]

  # GET /foods or /foods.json
  def index
    authorize Food, :index?
    @foods = Food.includes(:category).order(:name)
  end

  # GET /foods/1 or /foods/1.json
  def show
    authorize @food
    @food_variants = @food.food_variants.order(:name)
    @recipe_items = @food.recipe_items.includes(:ingredient)
  end

  # GET /foods/new
  def new
    @food = Food.new
    @categories = Category.order(:name)
    authorize @food
  end

  # GET /foods/1/edit
  def edit
    @categories = Category.order(:name)
    authorize @food
  end

  # POST /foods or /foods.json
  def create
    @food = Food.new(food_params)
    authorize @food

    if @food.save
      redirect_to foods_path, notice: "Foods created"
    else
      @categories = Category.all
      render 'foods/new', status: :unprocessable_entity
    end
  end

  # PATCH/PUT /foods/1 or /foods/1.json
  def update
    authorize @food
    if @food.update(food_params)
      redirect_to foods_path, notice: "Foods updated."
    else
      render 'foods/edit', status: :unprocessable_entity
    end
  end

  # DELETE /foods/1 or /foods/1.json
  def destroy
    authorize @food
    @food.destroy!

    redirect_to foods_path, notice: "Food removed."
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_food
      @food = Food.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def food_params
      params.require(:food).permit(:category_id, :name, :description, :base_price, :status, :image)
    end
end
