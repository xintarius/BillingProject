# settlement_grid
class WeekSettlementGrid
  include Datagrid

  scope do
    Invoice.select("DATE_TRUNC('week', created_at) AS week_start, SUM(brutto) AS brutto_sum, SUM(netto) AS netto_sum")
           .group("DATE_TRUNC('week', created_at)")
           .having("SUM(brutto) > 0 OR SUM(netto) > 0")
           .order("week_start DESC")
  end

  column(:brutto, header: -> { I18n.t('views.datagrid.settlements.gross') }, order: false) do |record|
    "#{record.brutto_sum.to_f / 100} zł"
  end

  column(:netto, header: -> { I18n.t('views.datagrid.settlements.net') }, order: false) do |record|
    "#{record.netto_sum.to_f / 100} zł"
  end

  column(:okres, header: -> { I18n.t('views.datagrid.settlements.billing_period') }) do |record|
    start_date = record.week_start.to_date
    end_date = start_date + 6.days
    "#{start_date.strftime('%d.%m.%Y')} - #{end_date.strftime('%d.%m.%Y')}"
  end
end

