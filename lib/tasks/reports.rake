# reports rake
namespace :reports do
  task generate_week_reports: :environment do
    start_date = Time.current.beginning_of_week
    end_date = Time.current.end_of_week
    User.find_each do |user|
      @logger.info("Creating report for user: #{user.id}")
      export = Export.create(user: user)

      begin
        csv_data = CSV.generate(
          write_headers: true,
          headers: ['Name', 'Invoice date', 'brutto', 'netto']
        ) do |csv|
          user.invoices.where(created_at: start_date..end_date).find_each do |invoice|
            csv << [
              invoice.name,
              invoice.invoice_date,
              invoice.brutto,
              invoice.netto
            ]
          end
        end

        file = "#{user.id}_#{Time.now.to_i}.csv"
        minio_path = "billing-csv/#{file}"
        io = StringIO.new(csv_data)
        io.rewind
        MinioClient.upload(minio_path, io)

        export.update!(file_path: minio_path)
      end
      @logger.info("Report for user #{user.id} ended")
    rescue StandardError => e
      @logger.info("Report error for user: #{user.id}: #{e.message}")
    end
    @logger.info('Reports done')
  end

  task delete_old_reports: :environment do
    @logger.info('Start to delete old reports...')
    start_date = Time.current.beginning_of_week - 1.week
    end_date = Time.current.end_of_week - 1.week
    exports = Export.where(created_at: start_date..end_date)
    @logger.info("Found #{exports.count} reports")

    exports.delete_all

    @logger.info('Old reports deleted')
  end
end
