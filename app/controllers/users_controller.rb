# users controller
class UsersController < ApplicationController
  layout 'dashboard_layout'
  def index
    @user_grid = UserGrid.new(params[:user_grid])
    @assets = @user_grid.assets.page(params[:page]).per(10)
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
    params.expect(user: %i[email password role_id]) if params[:user].present?
  end
end
