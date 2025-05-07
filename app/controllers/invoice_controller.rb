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
    @vat_types = InvoiceVatRate.pluck(:vat_rate, :id)
  end

  def create
    service_params
    flash[:notice] = 'Faktura została utworzona'
    redirect_to invoice_index_path
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error e.record.errors.full_messages.join(', ')
    flash[:error] = "Błąd przy tworzeniu faktury #{e.message}"
    redirect_to new_invoice_path
  end

  private

  def service_params
    vat = InvoiceVatRate.find(set_vat)
    company_id = Company.find_or_create_by!(nip: set_regex_nip)
    invoice_params = strong_params.to_h.merge(company_id: company_id.id,
                                              invoice_type_id: 1,
                                              brutto: set_brutto,
                                              netto: set_netto,
                                              invoice_vat_rate_id: vat.id)
    Invoice.create!(invoice_params)
    return if set_file.blank?

    ReaderService.send_file(set_file, company_id)
  end

  def set_file
    params[:invoice][:file]
  end

  def set_brutto
    params[:invoice][:brutto].to_s.gsub(',', '.').to_f * 100
  end

  def set_netto
    params[:invoice][:netto].to_s.gsub(',', '.').to_f * 100
  end

  def set_regex_nip
    params[:invoice][:nip].gsub(/[-\s]/, '')
  end

  def set_vat
    params[:invoice][:invoice_vat_rate].to_i
  end

  def strong_params
    return if params[:invoice].blank?

    params.expect(invoice: %i[name invoice_date invoice_nr brutto netto])
  end
end
