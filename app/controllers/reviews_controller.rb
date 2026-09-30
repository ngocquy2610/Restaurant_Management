class ReviewsController < ApplicationController
  before_action :authenticate_user!, except: %i[ index show ]
  before_action :set_review, only: %i[ show edit update destroy ]

  def index
    authorize Review, :index?

    @scope = policy_scope(Review).visible
    @scope = @scope.restaurant if params[:type] == "restaurant"
    @scope = @scope.meal       if params[:type] == "meal"

    @average_rating = @scope.average(:rating)&.round(1)
    @review_count   = @scope.count
    @reviews        = @scope.recent.page(params[:page]).per(6)
  end

  def show
    authorize @review
  end

  def new
    @review_type = resolved_review_type
    @reservation = reservation_for(@review_type)

    if @reservation.blank?
      redirect_to reviews_path, alert: "You can leave a review once a visit is complete."
      return
    end

    # Already reviewed? Send the customer to the review they can still edit
    # instead of rendering a form that is bound to fail on submit.
    existing = @review_type == :restaurant ? Review.for_customer(current_user, :restaurant).first : @reservation.meal_review
    if existing.present?
      redirect_to existing, notice: "You have already submitted this review — you can edit or delete it below."
      return
    end

    @review = Review.new(reservation: @reservation, review_type: @review_type)
    authorize @review
  end

  def restaurant
    reservation = Reservation.reviewable_for(current_user).first
    if reservation.blank?
      redirect_to reviews_path, alert: "You can review the restaurant after your first completed visit."
      return
    end

    redirect_to new_review_path(review_type: "restaurant", reservation_id: reservation.id)
  end

  def create
    @review_type = resolved_review_type
    @reservation = reservation_for(@review_type)

    @review = Review.new(
      reservation: @reservation,
      review_type: @review_type,
      rating: review_params[:rating],
      comment: review_params[:comment]
    )
    authorize @review

    if @review.save
      notify_role(:admin, title: "New customer review", body: review_notification_body(@review))
      redirect_to after_write_path(@review), notice: "Thank you for your review!"
    else
      render :new, status: :unprocessable_content
    end
  rescue ActiveRecord::RecordNotUnique   # double-submit race caught by the partial unique index
    @review.errors.add(:base, "This review has already been submitted.")
    render :new, status: :unprocessable_content
  end

  def edit
    authorize @review
  end

  def update
    authorize @review
    if @review.update(rating: review_params[:rating], comment: review_params[:comment])
      redirect_to @review, notice: "Review updated.", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @review
    reservation = @review.reservation
    @review.destroy!
    redirect_to reservation_path(reservation), notice: "Review removed.", status: :see_other
  end

  private

  def set_review
    @review = Review.find(params.expect(:id))
  end

  # review_type is whitelisted → a tampered value can never raise an enum ArgumentError.
  def resolved_review_type
    type = (params.dig(:review, :review_type).presence || params[:review_type].presence || "meal").to_s
    Review.review_types.key?(type) ? type.to_sym : :meal
  end

  def reservation_for(type)
    if type == :restaurant
      Reservation.reviewable_for(current_user).first
    else
      id = params.dig(:review, :reservation_id).presence || params[:reservation_id]
      current_user.reservations.find_by(id: id)
    end
  end

  def review_params
    params.require(:review).permit(:rating, :comment, :review_type, :reservation_id)
  end

  def after_write_path(review)
    review.restaurant? ? reviews_path(type: "restaurant") : reservation_path(review.reservation)
  end

  def review_notification_body(review)
    target = review.restaurant? ? "the restaurant" : "a meal at Table #{review.table&.table_number}"
    "#{review.reviewer_name} rated #{review.rating}/5 for #{target} (#{review.meal_label})."
  end
end
