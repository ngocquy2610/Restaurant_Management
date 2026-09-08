class AreasController < ApplicationController
  before_action :authenticate_user!
  before_action :set_area, only: %i[ edit update destroy ]

  def new
    @area = Area.new
    authorize @area
    render "admin/areas/new"
  end

  def create
    @area = Area.new(area_params)
    authorize @area

    if @area.save
      notify_user(
        recipient: current_user,
        title: "Area created",
        body: "The area #{@area.name} has been created."
      )
      redirect_to tables_path, notice: "Area added."
    else
      render 'admin/areas/new', status: :unprocessable_entity
    end
  end

  def edit
    authorize @area
    render "admin/areas/edit"
  end

  def update
    authorize @area
    if @area.update(area_params)
      notify_user(
        recipient: current_user,
        title: "Area updated",
        body: "The area #{@area.name} has been updated."
      )
      redirect_to tables_path, notice: "Area updated."
    else
      render 'admin/areas/edit', status: :unprocessable_entity
    end
  end

  def destroy
    authorize @area
    @area.destroy!
    notify_user(
      recipient: current_user,
      title: "Area destroyed",
      body: "The area #{@area.name} has been destroyed."
    )
    redirect_to tables_path, notice: "Area removed."
  end

  private

  def set_area
    @area = Area.find(params.expect(:id))
  end

  def area_params
    params.require(:area).permit(
      :area_type, :name, :floor_level, :image
    )
  end
end