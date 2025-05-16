# exports_controller
class ExportsController < ApplicationController
  layout 'dashboard_layout'

  def index
    @exports_grid = ExportGrid.new(params[:exports_grid_params])
  end
end
