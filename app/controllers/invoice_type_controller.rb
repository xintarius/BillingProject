# invoice_type_controller
class InvoiceTypeController < ApplicationController
  before_action :admin?
  layout 'dashboard_layout'

  def index
    @invoice_types_grid = InvoiceTypeGrid.new(params[:invoice_type_grid_params])
  end
end
