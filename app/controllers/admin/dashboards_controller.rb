class Admin::DashboardsController < ApplicationController
  before_action :authenticate_user!

  def index
    authorize User, :index?

    @from_date, @to_date = resolve_range
    @time_range = @from_date.beginning_of_day..@to_date.end_of_day

    @overview = RestaurantPerformanceService.new(
      from_date: @from_date,
      to_date: @to_date,
      time_range: @time_range
    ).overview

    @reservations = Reservation
      .where.not(status: [:completed, :rejected, :cancelled])
      .includes(:table, :user)
      .order(created_at: :desc)
      .page(params[:page])
      .per(5)

  end

  def performance
    authorize User, :index?

    @from_date, @to_date = resolve_range
    @time_range = @from_date.beginning_of_day..@to_date.end_of_day

    @performance = RestaurantPerformanceService.new(
      from_date: @from_date,
      to_date: @to_date,
      time_range: @time_range
    ).call

    @reservations = Reservation
      .where.not(status: [:completed, :rejected, :cancelled])
      .includes(:table, :user)
      .order(created_at: :desc)
      .page(params[:page])
      .per(5)

  end

  private

  def resolve_range
    default_to = Date.current
    default_from = default_to - 29.days

    if params[:from_date].blank? && params[:to_date].blank?
      return [default_from, default_to]
    end

    from = Date.iso8601(params[:from_date].to_s)
    to = Date.iso8601(params[:to_date].to_s)

    [from, to]
  rescue ArgumentError
    [default_from, default_to]
  end
end