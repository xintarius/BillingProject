namespace :state_daily_data do

  desc 'set repeat test data'
  task repeat_data: :environment do
    @logger = Logger.new('log/state_daily_data.log')
    @logger.info('start to change data')
    @logger.info('searching for recently used data')
    start_time_ago = Time.zone.now.beginning_of_day - 8.days
    end_time_ago = Time.zone.now.end_of_day - 8.days
    daily_data = DailyInvoice.where(created_at: start_time_ago..end_time_ago)
    @logger.info("found #{daily_data.count} rows")
    daily_data.update_all(created_at: Time.zone.now, updated_at: Time.zone.now)
  end
end
