# settlement controller
class SettlementController < ApplicationController
  before_action :authenticate_user!
  layout 'dashboard_layout'
  def index
    year = Time.zone.today.year
    total_weeks = Date.new(year, 12, 28).cweek

    # Get all invoices
    invoices = Invoice.where(created_at: Date.new(year, 1, 1)..Date.new(year, 12, 31))
    brutto_per_week = Hash.new(0)
    netto_per_week = Hash.new(0)

    # set invoices to each per week
    invoices.each do |invoice|
      week_number = invoice.created_at.to_date.cweek
      brutto_per_week[week_number] += invoice.brutto
      netto_per_week[week_number] += invoice.netto
    end

    # generate by week
    (1..total_weeks).map do |week|
      start_date = Date.commercial(year, week, 1).beginning_of_week
      end_date = start_date.end_of_week
      (start_date..end_date)
    end

    @settlement_grid = SettlementGrid.new(params[:settlement_grid])
    @assets = @settlement_grid.assets.page(params[:page]).per(10)
  end

end
