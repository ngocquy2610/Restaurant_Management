class FoodVariantsController < ApplicationController
  before_action :set_food_variant, only: %i[ show edit update destroy ]

  # GET /food_variants or /food_variants.json
  def index
    @food_variants = FoodVariant.all
  end

  # GET /food_variants/1 or /food_variants/1.json
  def show
  end

  # GET /food_variants/new
  def new
    @food_variant = FoodVariant.new
  end

  # GET /food_variants/1/edit
  def edit
  end

  # POST /food_variants or /food_variants.json
  def create
    @food_variant = FoodVariant.new(food_variant_params)

    respond_to do |format|
      if @food_variant.save
        format.html { redirect_to @food_variant, notice: "Food variant was successfully created." }
        format.json { render :show, status: :created, location: @food_variant }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @food_variant.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /food_variants/1 or /food_variants/1.json
  def update
    respond_to do |format|
      if @food_variant.update(food_variant_params)
        format.html { redirect_to @food_variant, notice: "Food variant was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @food_variant }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @food_variant.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /food_variants/1 or /food_variants/1.json
  def destroy
    @food_variant.destroy!

    respond_to do |format|
      format.html { redirect_to food_variants_path, notice: "Food variant was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_food_variant
      @food_variant = FoodVariant.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def food_variant_params
      params.fetch(:food_variant, {})
    end
end
