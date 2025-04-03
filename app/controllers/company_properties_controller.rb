# company_controller
class CompanyPropertiesController < ApplicationController
  layout 'dashboard_layout'

  def index
    @companies_grid = CompanyGrid.new(params[:company_grid])
    @assets = @companies_grid.assets.page(params[:page]).per(15)
  end
end
