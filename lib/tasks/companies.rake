namespace :companies do

  task create_test_companies: :environment do
    @logger.info('Start generate test companies')
    nip = Company.generate_nip
    name = Company.generate_name
    Company.create(nip: nip, name: name)
    @logger.info("Company with nip: #{nip} and name: #{name} generated")
  end
end
