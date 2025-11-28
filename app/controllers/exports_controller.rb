# exports_controller
class ExportsController < ApplicationController
  layout 'dashboard_layout'

  def index
    scope = Export.where(user_id: current_user.id).order(id: :desc)
    @exports_grid = ExportGrid.new(params[:exports_grid_params])
    @exports_grid.scope { scope }
    @assets = @exports_grid.assets.page(params[:page]).per(20)
  end

  def show
    @export = Export.find(params[:id])
  end

  def download
    @export = Export.find(params[:id])
    export_name = @export.export_name
    file_name = "##{export_name}_#{Time.now.to_i}.csv"
    send_data Base64.strict_decode64(@export.read_data),
              type: "application/csv; charset=binary",
              disposition: "attachment",
              filename: file_name.to_s
  end
end
