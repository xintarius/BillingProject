# lib/helpers/connection_helper.rb
module ConnectionHelper
  def self.safe_push(job_class, *args)
    retries ||= 0
    job_class.perform_async(*args)
  rescue RedisClient::ConnectionError, Errno::ETIMEDOUT => e
    puts "❗ Redis timeout: #{e.message}"
    retries += 1
    raise 'Nie udało się połączyć z Redisem' unless retries < 5

    sleep 3
    retry
  end
end
