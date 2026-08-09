class Users::SessionsController < Devise::SessionsController
  def create
    self.resource = warden.authenticate!(auth_options)
    sign_in(resource_name, resource)

    respond_to do |format|
      format.html { redirect_to after_sign_in_path_for(resource) }
      format.json { render json: { status: 'ok', user: user_payload(resource) }, status: :ok }
    end
  end

  def destroy
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))

    respond_to do |format|
      format.html { redirect_to root_path, notice: 'Logged out successfully.' }
      format.json { render json: { status: 'ok' }, status: :ok }
    end
  end

  private

  def user_payload(user)
    { id: user.id, email: user.email, full_name: user.full_name, role: user.role }
  end
end