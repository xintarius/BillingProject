
namespace :reports do
  task generate_week_reports: :environment do
    start_date = Time.current.beginning_of_week
    end_date = Time.current.end_of_week
    User.find_each do |user|
          puts "Tworzenie eksportu dla użytkownika #{user.id}"

          export = Export.create(user: user)

          begin
            Tempfile.create(['invoice_export_', 'csv']) do |tmp|
              CSV.open(tmp.path, 'w', write_headers: true, headers: ["Name", "Invoice date", "brutto", "netto"]) do |csv|
                user.invoices.where(created_at: start_date..end_date).find_each do |invoice|
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
                content_type: "text/csv"
              )
            end
            puts "Eksport dla użytkownika #{user.id} zakończony"
          rescue => e
            puts "Błąd eksportu dla użytkownika #{user.id}: #{e.message}"
          end
        end

        puts "Eksport faktur zakończony"
  end
end