class CategoriesController < ApplicationController
  before_action :set_category, only: %i[ show edit update destroy ]

  # GET /categories or /categories.json
  def index
    authorize Category, :index?

    @query = params[:q].to_s.strip
    @sort = params[:sort].presence_in(%w[newest oldest name_asc name_desc most_items fewest_items]) || "newest"

    dishes_count_sql = "(SELECT COUNT(*) FROM foods WHERE foods.category_id = categories.id)"

    scope = Category.all
    if @query.present?
      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(@query)}%"
      scope = scope.where("categories.name ILIKE ?", pattern)
    end

    scope = scope.select("categories.*", "#{dishes_count_sql} AS foods_count")

    scope = case @sort
            when "oldest"       then scope.order("categories.created_at ASC")
            when "name_asc"     then scope.order("categories.name ASC")
            when "name_desc"    then scope.order("categories.name DESC")
            when "most_items"   then scope.order(Arel.sql("#{dishes_count_sql} DESC, categories.name ASC"))
            when "fewest_items" then scope.order(Arel.sql("#{dishes_count_sql} ASC, categories.name ASC"))
            else                     scope.order("categories.created_at DESC")
            end

    @categories = scope.includes(:foods).page(params[:page]).per(8)

    @total_categories = Category.count
    @total_dishes = Food.count
    @empty_count = Category.left_joins(:foods).where(foods: { id: nil }).count
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
    @existing_categories = Category.order(:name).limit(10)
    @total_categories = Category.count
  end

  # GET /categories/1/edit
  def edit
    authorize @category
    @category_foods = @category.foods.order(:name).limit(6)
    @food_count = @category.foods.count
    @existing_categories = Category.where.not(id: @category.id).order(:name).limit(8)
  end

  # POST /categories or /categories.json
  def create
    @category = Category.new(category_params)
    authorize @category

    if @category.save
      notify_user(
        recipient: current_user,
        title: "Category created",
        body: "The category #{@category.name} has been created.",
        redirect_url: category_path(@category)
      )
      redirect_to categories_path, notice: "Category added."
    else
      @existing_categories = Category.order(:name).limit(10)
      @total_categories = Category.count
      render 'categories/new', status: :unprocessable_entity
    end
  end

  # PATCH/PUT /categories/1 or /categories/1.json
  def update
    authorize @category
    if @category.update(category_params)
      notify_user(
        recipient: current_user,
        title: "Category updated",
        body: "The category #{@category.name} has been updated.",
        redirect_url: category_path(@category)
      )
      redirect_to categories_path, notice: "Category updated."
    else
      @category_foods = @category.foods.order(:name).limit(6)
      @food_count = @category.foods.count
      @existing_categories = Category.where.not(id: @category.id).order(:name).limit(8)
      render 'categories/edit', status: :unprocessable_entity
    end
  end

  # DELETE /categories/1 or /categories/1.json
  def destroy
    authorize @category
    @category.destroy!
      notify_user(
        recipient: current_user,
        title: "Category destroyed",
        body: "The category #{@category.name} has been destroyed.",
        redirect_url: categories_path
      )
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
