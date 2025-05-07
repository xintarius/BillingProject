env :SHELL, "/bin/bash"
env :PATH, "/usr/local/bundle/bin:/usr/local/bundle/gems/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
env :BUNDLE_APP_CONFIG, "/usr/local/bundle"
env :GEM_PATH, "/usr/local/bundle"
env :PATH, ENV["PATH"]
ENV.each { |k, v| env(k, v) }
set :environment, ENV["RAILS_ENV"]
set :output, "log/cron.log"
set :job_template, nil
job_type :command, "cd :path && :task :output"

every 1.day, at: '23:59' do
  rake 'daily_invoice.create_daily_invoices'
end

every 1.hour do
  rake 'invoices:check_invoices_status'
end