require 'aws-sdk-s3'
# minio client
class MinioClient
  @@s3_client = nil
  def self.connection
    @@s3_client ||= Aws::S3::Resource.new(
      endpoint: ENV.fetch('ENDPOINT', nil),
      access_key_id: ENV.fetch('ACCESS_KEY_ID', nil),
      secret_access_key: ENV.fetch('SECRET_ACCESS_KEY', nil),
      region: ENV.fetch('REGION', nil),
      force_path_style: true
    )
  end

  def self.upload(path, file)
    file.rewind
    obj = connection.bucket(ENV.fetch('DEFAULT_BUCKET', nil)).object(path)
    obj.put(body: file.read)
  end

  def self.list_files(prefix = '')
    response = connection.bucket(ENV.fetch('DEFAULT_BUCKET', nil))
    response.objects(prefix: prefix).map(&:key)
  end

  def self.get_object(file_key)
    bucket_name = ENV.fetch('DEFAULT_BUCKET', nil)
    obj = connection.bucket(bucket_name).object(file_key)

    unless obj.exists?
      Rails.debugger.info "🚨 File #{file_key} not fount in Minio (bucket: #{bucket_name})"
      return nil
    end

    begin
      content = obj.get.body.read
      Rails.debugger.info "File download: #{file_key}, size: #{content.size}"
      content
    rescue StandardError => e
      Rails.debugger.info "Download error #{file_key}: #{e.message}"
      nil
    end
  end
end
