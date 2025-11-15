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
    export = current_user.exports.find(params[:id])
    unless export.file.attached?
      redirect_to exports_path, alert: "Plik exportu nie jest jeszcze gotowy"
      return
    end
    redirect_to rails_blob_url(export.file, disposition: "attachment")
  end

end
