class PromotionsController < ApplicationController
  before_action :set_promotion, only: %i[ show edit update destroy ]

  # GET /promotions or /promotions.json
  def index
    authorize Promotion, :index?
    @promotions = Promotion.all
  end

  # GET /promotions/1 or /promotions/1.json
  def show
    authorize @promotion
  end

  # GET /promotions/new
  def new
    @promotion = Promotion.new
    authorize @promotion
  end

  # GET /promotions/1/edit
  def edit
    authorize @promotion
  end

  # POST /promotions or /promotions.json
  def create
    @promotion = Promotion.new(promotion_params)
    authorize @promotion

    if @promotion.save
      notify_user(
        recipient: current_user,
        title: "Promotion created",
        body: "The promotion #{@promotion.name} has been created."
      )
      redirect_to promotions_path, notice: "Promotion added."
    else
      render "promotions/new", status: :unprocessable_content
    end
  end

  # PATCH/PUT /promotions/1 or /promotions/1.json
  def update
    authorize @promotion
    if @promotion.update(promotion_params)
      notify_user(
        recipient: current_user,
        title: "Promotion updated",
        body: "The promotion #{@promotion.name} has been updated."
      )
      redirect_to promotions_path, notice: "Promotion updated."
    else
      render "promotions/edit", status: :unprocessable_content
    end
  end

  # DELETE /promotions/1 or /promotions/1.json
  def destroy
    authorize @promotion
    @promotion.destroy!
    notify_user(
      recipient: current_user,
      title: "Promotion destroyed",
      body: "The promotion #{@promotion.name} has been destroyed."
    )
    redirect_to promotions_path, notice: "Promotion removed."
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_promotion
      @promotion = Promotion.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def promotion_params
      params.require(:promotion).permit(
        :name, :discount_type,
        :discount_value, :start_date, :end_date,
        :status, :image
      )
    end
end
