require 'csv'
namespace :raw_data do
  desc 'Generating records from file'
  task generate_raw_data: :environment do
    file_path = Rails.root.join('db/test_data.csv').to_s
    puts file_path.inspect
    return unless File.exist?(file_path)


    CSV.foreach(file_path, headers: true) do |row|
      Company.create(
        name: row['Name'],
        nip: row['NIP'],
        invoice_date: row['invoice date'],
        netto: row['netto'],
        vat: row['VAT'],
        brutto: row['brutto']
      )
    end
  end


  task delete_invalid_data: :environment do
    vat = 23
    companies = Company.where.not(vat: vat)


    companies.delete_all
  end
end
