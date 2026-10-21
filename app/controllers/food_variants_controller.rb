class FoodVariantsController < ApplicationController
  before_action :set_food_variant, only: %i[ show edit update destroy ]

  # GET /food_variants or /food_variants.json
  def index
    authorize FoodVariant, :index?

    @query = params[:q].to_s.strip
    @food_filter = params[:food_id].presence
    @sort = params[:sort].presence_in(%w[newest oldest name_asc name_desc price_asc price_desc]) || "newest"
    @foods_for_filter = Food.order(:name)

    scope = FoodVariant.includes(food: :category)

    if @query.present?
      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(@query)}%"
      scope = scope.joins(food: :category).where(
        "food_variants.name ILIKE :p OR foods.name ILIKE :p OR categories.name ILIKE :p",
        p: pattern
      ).distinct
    end

    scope = scope.where(food_id: @food_filter) if @food_filter.present?

    scope = case @sort
            when "oldest" then scope.order("food_variants.created_at ASC")
            when "name_asc" then scope.order("food_variants.name ASC")
            when "name_desc" then scope.order("food_variants.name DESC")
            when "price_asc" then scope.order("food_variants.price_adjustment ASC")
            when "price_desc" then scope.order("food_variants.price_adjustment DESC")
      else scope.order("food_variants.created_at DESC")
    end

    @food_variants = scope.page(params[:page]).per(8)

    @total_variants = FoodVariant.count
    @total_dishes = FoodVariant.distinct.count(:food_id)
    @avg_adjustment = FoodVariant.average(:price_adjustment)
  end

  # GET /food_variants/1 or /food_variants/1.json
  def show
    authorize @food_variant
    @food = @food_variant.food
    @sibling_variants = @food ? @food.food_variants.where.not(id: @food_variant.id).order(:name) : FoodVariant.none
    @dish_variant_count = @food ? @food.food_variants.count : 0
  end

  # GET /food_variants/new
  def new
    @food_variant = FoodVariant.new(food_id: params[:food_id].presence)
    @foods = Food.includes(:category, :food_variants).order(:name)
    @same_dish_variants = @food_variant.food_id.present? ? FoodVariant.where(food_id: @food_variant.food_id).order(:name) : FoodVariant.none
    authorize @food_variant
  end

  # GET /food_variants/1/edit
  def edit
    @foods = Food.includes(:category, :food_variants).order(:name)
    @same_dish_variants = @food_variant.food ? @food_variant.food.food_variants.where.not(id: @food_variant.id).order(:name) : FoodVariant.none
    authorize @food_variant
  end

  # POST /food_variants or /food_variants.json
  def create
    @food_variant = FoodVariant.new(food_variant_params)
    authorize @food_variant

    if @food_variant.save
      notify_user(
        recipient: current_user,
        title: "Food variant created",
        body: "The food variant #{@food_variant.name} of #{@food_variant.food} has been created.",
        redirect_url: food_variant_path(@food_variant)
      )
      redirect_to food_variants_path, notice: "Food variant was successfully created."
    else
      @foods = Food.includes(:category, :food_variants).order(:name)
      @same_dish_variants = @food_variant.food_id.present? ? FoodVariant.where(food_id: @food_variant.food_id).order(:name) : FoodVariant.none
      render "food_variants/new", status: :unprocessable_content
    end
  end

  # PATCH/PUT /food_variants/1 or /food_variants/1.json
  def update
    authorize @food_variant

    if @food_variant.update(food_variant_params)
      notify_user(
        recipient: current_user,
        title: "Food variant updated",
        body: "The food variant #{@food_variant.name} of #{@food_variant.food} has been updated.",
        redirect_url: food_variant_path(@food_variant)
      )
      redirect_to food_variant_path, notice: "Food variant was successfully updated."
    else
      @foods = Food.includes(:category, :food_variants).order(:name)
      @same_dish_variants = @food_variant.food ? @food_variant.food.food_variants.where.not(id: @food_variant.id).order(:name) : FoodVariant.none
      render "food_variants/edit", status: :unprocessable_content
    end
  end

  # DELETE /food_variants/1 or /food_variants/1.json
  def destroy
    authorize @food_variant
    @food_variant.destroy!
    notify_user(
      recipient: current_user,
      title: "Food variant destroyed",
      body: "The food variant #{@food_variant.name} of #{@food_variant.food} has been destroyed.",
      redirect_url: food_variants_path
    )
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
