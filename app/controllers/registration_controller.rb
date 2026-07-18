class RegistrationController < ApplicationController
  allow_unauthenticated_access

  def new
    @user = User.new
  end

  def create
    @user = User.create(user_params)
    if @user.save
      start_new_session_for(@user)
      redirect_to dashboard_path
    else
      render :new
    end
  end

  private

  def user_params
    params.expect(user: [ :email_address, :password, :password_confirmation ])
  end
end
