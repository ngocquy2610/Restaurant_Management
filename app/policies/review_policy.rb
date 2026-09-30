class ReviewPolicy < ApplicationPolicy
  def index? = true
  def show?  = true
  def new?   = create?

  def create?
    user.present? && record.reservation.present? &&
      record.reservation.user_id == user.id && record.reservation.reviewable?
  end

  def create_restaurant?
    user.present? &&
      !Review.for_customer(user, :restaurant).exists? &&
      Reservation.reviewable_for(user).any?
  end

  def update?  = user.present? && (owner? || user.admin?)
  def edit?    = update?
  def destroy? = update?

  class Scope < Scope
    def resolve = scope.all
  end

  private

  def owner? = user.present? && record.user_id == user.id
end
