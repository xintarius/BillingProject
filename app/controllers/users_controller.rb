# users controller
class UsersController < ApplicationController
  layout 'dashboard_layout'
  def index
    @users = User.all
  end

  def new
    @user = User.new
  end

  def create
    User.create!(strong_params)
    redirect_to users_index_path
    flash[:success] = 'Successfully created new user!'
  rescue ActiveRecord::RecordInvalid => e
    flash[:error] = "error creating a user: #{e.message}"
    redirect_to new_user_path
  end

  private

  def strong_params
    params.expect(user: %i[email password]) if params[:user].present?
  end
end
