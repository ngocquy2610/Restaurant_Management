class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: %i[ show edit update destroy ]
  before_action :set_member_tiers, only: %i[ edit update ]

  # GET /users or /users.json
  def index
    authorize User, :index?
    users = policy_scope(User)
    @customers = users.customer
    @employees = users.where.not(role: [:admin, :customer])
    render 'admin/users/index'
  end

  # GET /users/1 or /users/1.json
  def show
    authorize @user

    @current_tier = @user.current_member_tier
    @next_tier = @user.next_member_tier
    @amount_to_next_tier = @user.amount_to_next_member_tier
  end

  # GET /users/new
  def new
    @user = User.new
    authorize @user
  end

  # GET /users/1/edit
  def edit
    authorize @user
  end

  # POST /users or /users.json
  def create
    @user = User.new(user_params)
    authorize @user

    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: "User was successfully created." }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @user.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /users/1 or /users/1.json
  def update
    authorize @user
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to @user, notice: "User was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @user.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /users/1 or /users/1.json
  def destroy
    authorize @user
    @user.destroy!

    respond_to do |format|
      format.html { redirect_to users_path, notice: "User was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    def set_member_tiers
      @member_tiers = MemberTier.order(:active_price, :id)
    end

    # Only allow a list of trusted parameters through. Password is intentionally
    # NOT permitted here - it is changed through the dedicated password/Devise flow.
    # Avatar is uploaded as an attached image (Active Storage), not a URL.
    def user_params
      permitted = %i[ full_name email phone location avatar ]
      permitted += %i[ role status member_tier_id year_spend ] if current_user.admin?

      params.require(:user).permit(permitted)
    end
end
