class CategoriesController < ApplicationController
  before_action :set_category, only: %i[ show edit update destroy ]

  # GET /categories or /categories.json
  def index
    authorize Category, :index?
    @categories = Category.all
  end

  # GET /categories/1 or /categories/1.json
  def show
    authorize @category
    @foods = @category.foods
    @food_variants = []
    @foods.each do |food|
      if food.food_variants.any?
        @food_variants.concat(food.food_variants)
      end
    end
  end

  # GET /categories/new
  def new
    @category = Category.new
    authorize @category
  end

  # GET /categories/1/edit
  def edit
    authorize @category
  end

  # POST /categories or /categories.json
  def create
    @category = Category.new(category_params)
    authorize @category

    if @category.save
      redirect_to categories_path, notice: "Category added."
    else
      render 'categories/new', status: :unprocessable_entity
    end
  end

  # PATCH/PUT /categories/1 or /categories/1.json
  def update
    authorize @category
    if @category.update(category_params)
      redirect_to categories_path, notice: "Category updated."
    else
      render 'categories/edit', status: :unprocessable_entity
    end
  end

  # DELETE /categories/1 or /categories/1.json
  def destroy
    authorize @category
    @category.destroy!

    redirect_to categories_path, notice: "Category removed."
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_category
      @category = Category.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def category_params
     params.require(:category).permit(:name)
    end
end
