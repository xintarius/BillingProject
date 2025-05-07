# invoice_vat_type_controller
class InvoiceVatRateController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin
  layout 'dashboard_layout'

  def index
    @vat_rates_grid = InvoiceVatRateGrid.new(params[:invoice_vat_type_grid])
  end

  def new
    @invoice_vat_type = InvoiceVatRate.new
  end

  def create
    InvoiceVatRate.create!(strong_params)
    redirect_to invoice_vat_rate_index_path
    flash[:notice] = 'Vat type successfully created'
  rescue ActiveRecord::RecordInvalid => e
    redirect_to new_invoice_vat_rate_path
    flash[:error] = "Error with adding vat type #{e.message}"
  end

  private

  def strong_params
    params.expect(invoice_vat_rate: [:vat_rate])
  end
end
