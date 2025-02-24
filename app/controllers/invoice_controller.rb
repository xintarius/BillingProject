# invoices controller
class InvoiceController < ApplicationController
  before_action :authenticate_user!
  layout 'dashboard_layout'
  def index; end

  def new
    @invoice = Invoice.new
  end
end


# working with invoices, adding features like add invoice and the system will scan it
# add pdf file in to site, add nip, name, address, invoice number, date