require 'aws-sdk-s3'
# minio client
class MinioClient
  def self.upload(path, file)
    s3 = Aws::S3::Resource.new(
      endpoint: ENV.fetch('ENDPOINT', nil),
      access_key_id: ENV.fetch('ACCESS_KEY_ID', nil),
      secret_access_key: ENV.fetch('SECRET_ACCESS_KEY', nil),
      region: ENV.fetch('REGION', nil),
      force_path_style: true
    )

    file.rewind
    obj = s3.bucket(ENV.fetch('DEFAULT_BUCKET', nil)).object(path)
    obj.put(body: file.read)
  end
end
