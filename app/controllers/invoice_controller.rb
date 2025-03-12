# invoices controller
class InvoiceController < ApplicationController
  before_action :authenticate_user!
  layout 'dashboard_layout'
  def index
    @invoices_grid = InvoiceGrid.new(params[:invoice_grid_params])
    @assets = @invoices_grid.assets.page(params[:page]).per(10)
  end

  def new
    @invoice = Invoice.new
  end

  def create
    file = params[:invoice][:file]
    company_id = Company.find_or_create_by!(nip: params[:invoice][:nip])
    invoice_params = strong_params.to_h.merge(company_id: company_id.id, invoice_type_id: 1)
    Invoice.create!(invoice_params)
    ReaderService.send_file(file, company_id)
    flash[:notice] = 'Faktura została utworzona'
    redirect_to invoice_index_path
  rescue ActiveRecord::RecordInvalid => e
    puts e.message.inspect
    flash[:error] = "Błąd przy tworzeniu faktury #{e.message}"
    redirect_to new_invoice_path
  end

  private

  def strong_params
    params.expect(invoice: %i[name invoice_date invoice_nr brutto vat netto]) if params[:invoice].present?
  end
end
