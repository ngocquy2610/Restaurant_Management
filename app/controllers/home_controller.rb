class HomeController < ApplicationController
  def index
    @users = User.all
    @promotions = Promotion.with_attached_image.where(status: :published)
  end
end
