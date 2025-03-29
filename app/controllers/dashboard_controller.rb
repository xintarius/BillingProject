# dashboard controller
class DashboardController < ApplicationController
  before_action :authenticate_user!
  layout 'dashboard_layout'

  def dashboard
    generate_invoice_chart_data
  end

  private

  def generate_invoice_chart_data
    @invoice_data = {}
    daily_invoice = DailyInvoice.where(date: data_range)
                                .select("CONCAT(TO_CHAR(MIN(date), 'YYYY-MM-DD'), ' to ', TO_CHAR(MAX(date), 'YYYY-MM-DD')) AS date,
                                SUM(brutto_count) as brutto")
                                .group('date')
                                .order('date')

    indexed_data = daily_invoice.index_by { |record| record.date.to_s }
    index_data(indexed_data, @invoice_data)
    @invoice_data
  end

  def index_data(indexed_data, invoice_data)
    data_range.each do |date|
      date_str = date.to_s
      invoice_data[date_str] = indexed_data[date_str]&.brutto.to_i
    end
  end

  def data_range
    7.days.ago.to_date..1.day.ago.to_date
  end
end
