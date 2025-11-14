require 'helpers/rake_helper'

namespace :runner do
  include Helpers::RakeHelper

  task :run, [:task_name] => :environment do |_task, args|
    task_name = args[:task_name]
    return if task_name.blank?

    $stdout.sync = true
    @logger = Logger.new("./log#{task_name.gsub(':', '-')}.log")

      cron_lock task_name.gsub(':', '-') do
        @logger.info 'Start'
        Rake::Task[task_name].invoke
        @logger.info 'end'
      end
  end
end