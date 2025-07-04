# company_controller
class CompanyPropertiesController < ApplicationController
  layout 'dashboard_layout'

  def index
    member_ids = Member.where(user_id: current_user.id).select('company_id')
    @companies_grid = CompanyGrid.new(params[:company_grid]) do |scope|
      scope.where(id: member_ids).where(member_id: nil)
    end
    @assets = @companies_grid.assets.page(params[:page]).per(15)
  end
end
