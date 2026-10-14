class ReviewsController < ApplicationController
  before_action :authenticate_user!, except: %i[ index show ]
  before_action :set_review, only: %i[ show edit update destroy ]

  def index
    authorize Review, :index?

    @scope = policy_scope(Review).visible

    @average_rating = @scope.average(:rating)&.round(1)
    @review_count   = @scope.count
    @reviews        = @scope.recent.page(params[:page]).per(6)
  end

  def show
    authorize @review
  end

  def new
    # Already reviewed? Send the customer to the review they can still edit
    # instead of rendering a form that is bound to fail on submit.
    existing = Review.for_customer(current_user).first
    if existing.present?
      redirect_to existing, notice: "You have already submitted this review — you can edit or delete it below."
      return
    end

    @reservation = reservation_for_review
    if @reservation.blank?
      redirect_to reviews_path, alert: "You can leave a review once a visit is complete."
      return
    end

    @review = Review.new(reservation: @reservation)
    authorize @review
  end

  def restaurant
    reservation = Reservation.reviewable_for(current_user).first
    if reservation.blank?
      redirect_to reviews_path, alert: "You can review the restaurant after your first completed visit."
      return
    end

    redirect_to new_review_path(reservation_id: reservation.id)
  end

  def create
    @reservation = reservation_for_review

    @review = Review.new(
      reservation: @reservation,
      rating: review_params[:rating],
      comment: review_params[:comment],
      image: review_params[:image]
    )
    authorize @review

    if @review.save
      notify_role(:admin, title: "New customer review", body: review_notification_body(@review),
          redirect_url: review_path(@review))
      redirect_to after_write_path(@review), notice: "Thank you for your review!"
    else
      render :new, status: :unprocessable_content
    end
  rescue ActiveRecord::RecordNotUnique   # double-submit race caught by the unique index
    @review.errors.add(:base, "This review has already been submitted.")
    render :new, status: :unprocessable_content
  end

  def edit
    authorize @review
  end

  def update
    authorize @review

    if review_params[:image].present?
      @review.image.attach(review_params[:image])
    end

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

  # The visit the review is written against: the one the customer picked, or
  # their most recent finished visit.
  def reservation_for_review
    id = params.dig(:review, :reservation_id).presence || params[:reservation_id]
    return current_user.reservations.find_by(id: id) if id.present?

    Reservation.reviewable_for(current_user).first
  end

  def review_params
    params.require(:review).permit(:rating, :comment, :reservation_id, :image)
  end

  def after_write_path(_review) = reviews_path

  def review_notification_body(review)
    "#{review.reviewer_name} rated #{review.rating}/5 for the restaurant (#{review.meal_label})."
  end
end
