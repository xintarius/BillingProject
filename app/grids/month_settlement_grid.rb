# month settlement grid
class MonthSettlementGrid
  include Datagrid

  scope do
    Invoice.select("DATE_TRUNC('month', created_at) AS month_start, SUM(brutto) AS brutto_sum, SUM(netto) AS netto_sum")
           .group("DATE_TRUNC('month', created_at)")
           .having("SUM(brutto) > 0 OR SUM(netto) > 0")
           .order("month_start DESC")
  end

  column(:brutto, header: -> { I18n.t('views.datagrid.settlements.gross') }, order: false) do |record|
    "#{record.brutto_sum.to_f / 100} zł"
  end

  column(:netto, header: -> { I18n.t('views.datagrid.settlements.net') }, order: false) do |record|
    "#{record.netto_sum.to_f / 100} zł"
  end

  column(:okres, header: -> { I18n.t('views.datagrid.settlements.billing_period') }) do |record|
    start_date = record.month_start.beginning_of_month.to_date
    end_date = record.month_start.end_of_month.to_date
    "#{start_date.strftime('%d.%m.%Y')} - #{end_date.strftime('%d.%m.%Y')}"
  end
end
