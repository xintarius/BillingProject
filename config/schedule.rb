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
  rake 'runner:run[daily_invoice:create_daily_invoices]'
end

every 1.hour do
  rake 'runner:run[invoice:check_invoices_status]'
end

every 1.day, at: '00:05' do
  rake 'runner:run[invoice:check_and_raise_invoice_status]'
end

every 1.day, at: '13:00' do
  rake 'runner:run[reports:generate_week_reports]'
end

every 1.day, at: '10:00' do
  rake 'runner:run[reports:delete_old_reports]'
end

every 1.day, at: '12:00' do
  rake 'runner:run[state_daily_data:repeat_data]'
end