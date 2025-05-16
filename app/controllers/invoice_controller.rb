# invoices controller
class InvoiceController < ApplicationController
  before_action :authenticate_user!
  layout 'dashboard_layout'
  def index
    scope = Invoice.where(user_id: current_user.id).order(id: :desc)
    @invoices_grid = InvoiceGrid.new(params[:invoice_grid_params] || {})
    @invoices_grid.current_user = current_user
    @invoices_grid.scope { scope }
    @assets = @invoices_grid.assets.page(params[:page]).per(10)
  end

  def show
    @invoice_statistic = Invoice.find(params[:id])
    @invoice_errors = convert_description_errors(@invoice_statistic)
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
    invoice_params = strong_params.to_h.merge(company_id: find_company.id,
                                              invoice_type_id: 1,
                                              brutto: set_brutto,
                                              netto: set_netto,
                                              invoice_vat_rate_id: find_vat.id,
                                              user_id: current_user.id)
    Invoice.create!(invoice_params)
    send_file_or_return
  end

  def send_file_or_return
    return if set_file.blank?

    create_member
    ReaderService.send_file(set_file, find_company)
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

  def find_vat
    InvoiceVatRate.find(set_vat)
  end

  def find_company
    Company.find_or_create_by!(nip: set_regex_nip)
  end

  def create_member
    Member.create!(user_id: current_user.id, company_id: find_company.id)
  end

  def convert_description_errors(invoice)
    return if invoice.description_error.blank?

    parse_errors = JSON.parse(invoice.description_error)
    parse_errors.map { |e| translate_error(e) }.compact
  end

  def translate_error(error)
    case error
    when /NIP error/i
      'Problem z błędnie wpisanym nipem.'
    when /Cash error/i
      'Problem z błędnie wpisaną kwotą.'
    else
      'Wystapił nieznany błąd.'
    end
  end

  def set_vat
    params[:invoice][:invoice_vat_rate].to_i
  end

  def strong_params
    return if params[:invoice].blank?

    params.expect(invoice: %i[name invoice_date invoice_nr brutto netto user_id])
  end
end
