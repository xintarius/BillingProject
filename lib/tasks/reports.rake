# reports rake
namespace :reports do
  task generate_week_reports: :environment do
    start_date = Time.current.beginning_of_week
    end_date = Time.current.end_of_week
    User.find_each do |user| 
      @logger.info("Creating report for user: #{user.id}")

      export = Export.create(user: user)

      begin
        Tempfile.create(%w[invoice_export_ csv]) do |tmp|
          CSV.open(tmp.path, 'w', write_headers: true,
                                  headers: ['Name', 'Invoice date', 'brutto', 'netto']) do |csv|
            user.Invoice.where(created_at: start_date..end_date).find_each do |invoice|
              csv << [
                invoice.name,
                invoice.invoice_date,
                invoice.brutto,
                invoice.netto
              ]
            end
          end

          export.file.attach(
            io: File.open(tmp.path),
            filename: "invoices_user_#{user.id}_#{Time.now.to_i}.csv",
            content_type: 'text/csv'
          )
        end
        @logger.info("Report for user #{user.id} ended")
      rescue StandardError => e
        @logger.info("Report error for user: #{user.id}: #{e.message}")
      end 
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
