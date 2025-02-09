# invoices controller
class InvoiceController < ApplicationController
  before_action :authenticate_user!
  layout 'dashboard_layout'
  def index; end
end
