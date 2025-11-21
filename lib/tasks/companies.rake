namespace :companies do

  task create_test_companies: :environment do
    @logger.info('Start generate test companies')
    nip = Company.generate_nip
    name = Company.generate_name
    @logger.info("nip: #{nip} generated")
    Company.create(nip: nip, company_name: name)
  end
end
