module Helpers
  module RakeHelper
    def cron_lock(cron_name)
      path = Rails.root.join('tmp', 'cron', "#{cron_name}.lock")
      mkdir_p path.dirname unless path.dirname.directory?

      file = path.open('w')
      return if file.flock(File::LOCK_EX | File::LOCK_NB) == false

      yield
    end
  end
end