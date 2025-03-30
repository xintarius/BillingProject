# roles_controller
class RolesController < ApplicationController
  layout 'dashboard_layout'
  def index
    @roles_grid = RoleGrid.new(params[:role_grid])
    @assets = @roles_grid.assets.page(params[:page]).per(10)
  end

  def new
    @role = Role.new
  end

  def create
    role = Role.create!(strong_params)
    redirect_to roles_path
    flash[:success] = "rola #{role.name} dodana"
  rescue ActiveRecord::RecordInvalid => e
    redirect_to new_role_path
    flash[:error] = "error creating a role #{e.message}"
  end

  private

  def strong_params
    params.expect(role: %i[code name description]) if params[:role].present?
  end
end
