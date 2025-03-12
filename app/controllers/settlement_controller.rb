# settlement controller
class SettlementController < ApplicationController
  before_action :authenticate_user!
  layout 'dashboard_layout'
  def index
    @weeks = []
    @brutto_per_week = []
    @netto_per_week = []
    year = Time.zone.today.year
    total_weeks = Date.new(year,12, 28).cweek
    (1..total_weeks).each do |week|
      start_date = Date.commercial(year, week, 1).beginning_of_week
      end_date = (start_date + 6.days).end_of_week
      @weeks << (start_date..end_date)
      @brutto_per_week[week] = Invoice.where(created_at: start_date..end_date).sum(:brutto)
      @netto_per_week[week] = Invoice.where(created_at: start_date..end_date).sum(:netto)
    end
    @settlement_grid = SettlementGrid.new(params[:settlement_grid])
    @assets = @settlement_grid.assets.page(params[:page]).per(10)
  end
end
