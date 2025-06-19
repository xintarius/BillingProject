require 'aws-sdk-s3'
# minio client
class MinioClient
  @@s3_client = nil
  @@s3_resource = nil
  def self.connection
    @@s3_resource ||= Aws::S3::Resource.new(
      endpoint: ENV.fetch('ENDPOINT', nil),
      access_key_id: ENV.fetch('ACCESS_KEY_ID', nil),
      secret_access_key: ENV.fetch('SECRET_ACCESS_KEY', nil),
      region: ENV.fetch('REGION', nil),
      force_path_style: true
    )
  end

  def self.client
    @@s3_client ||= Aws::S3::Client.new(
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
      puts "File #{file_key} not fount in Minio (bucket: #{bucket_name})"
      return nil
    end

    begin
      content = obj.get.body.read
      puts "File download: #{file_key}, size: #{content.size}"
      content
    rescue StandardError => e
      puts "Download error #{file_key}: #{e.message}"
      nil
    end
  end

  def self.list_client_files(prefix = '')
    bucket_name = ENV.fetch('DEFAULT_BUCKET', nil)
    response = client.list_objects_v2(
      bucket: bucket_name,
      prefix: prefix
    )

    # return key list files
    response.contents.map(&:key)
  end

  def self.delete_file(files_to_delete)
    bucket_name = ENV.fetch('DEFAULT_BUCKET', nil)

    objects = files_to_delete.map { |key| { key: key } }

    begin
      client.delete_objects(
        bucket: bucket_name,
        delete: { objects: objects }
      )
    rescue StandardError => e
      puts e.message
    end
  end

  def self.presigned_url(filename)
    signer = Aws::S3::Presigner.new(client: @@s3_client)
    signer.presigned_url(:get_object, bucket: ENV['DEFAULT_BUCKET'], key: filename, expires_in: 3600)
  end
end
