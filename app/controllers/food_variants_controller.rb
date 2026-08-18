class FoodVariantsController < ApplicationController
  before_action :set_food_variant, only: %i[ show edit update destroy ]

  # GET /food_variants or /food_variants.json
  def index
    authorize FoodVariant, :index?
    @food_variants = FoodVariant.includes(:food).order(:name)
  end

  # GET /food_variants/1 or /food_variants/1.json
  def show
    authorize @food_variant
  end

  # GET /food_variants/new
  def new
    @food_variant = FoodVariant.new
    @foods = Food.order(:name)
    authorize @food_variant
  end

  # GET /food_variants/1/edit
  def edit
    @foods = Food.order(:name)
    authorize @food_variant
  end

  # POST /food_variants or /food_variants.json
  def create
    @food_variant = FoodVariant.new(food_variant_params)
    authorize @food_variant

    if @food_variant.save
      redirect_to food_variants_path, notice: "Food variant was successfully created."
    else
      @foods = Food.order(:name)
      render "food_variants/new", status: :unprocessable_content
    end
  end

  # PATCH/PUT /food_variants/1 or /food_variants/1.json
  def update
    authorize @food_variant

    if @food_variant.update(food_variant_params)
      redirect_to food_variant_path, notice: "Food variant was successfully updated."
    else
      @foods = Food.order(:name)
      render "food_variants/edit", status: :unprocessable_content
    end
  end

  # DELETE /food_variants/1 or /food_variants/1.json
  def destroy
    authorize @food_variant
    @food_variant.destroy!

    redirect_to food_variants_path, notice: "Food variant was successfully destroyed."
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_food_variant
      @food_variant = FoodVariant.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def food_variant_params
      params.require(:food_variant).permit(:food_id, :name, :price_adjustment)
    end
end
