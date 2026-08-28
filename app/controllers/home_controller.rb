class HomeController < ApplicationController
  def index
    @users = User.all
    @promotions = Promotion.with_attached_image
                          .where(status: :published)
                          .where("start_date <= ?", Time.current)
                          .where("end_date >= ?", Time.current)
    @featured_foods = Food.with_attached_image
                          .joins(:category)
                          .where(status: :active)
                          .includes(:category)
                          .order(created_at: :desc)
                          .limit(3)
  end
end
