# invoice model
class Invoice < ApplicationRecord
  belongs_to :company
  belongs_to :invoice_type
  belongs_to :invoice_vat_rate
  belongs_to :user
  attr_accessor :nip


  def self.equal_data(files)
    data_from_minio = MinioClient.list_files('uploads/')
    result = files & data_from_minio
    recognize_data(result)
  end

  def self.recognize_data(files)
    files.each do |file|
      ConnectionHelper.safe_push(OcrWorker, file)
    end
  end

  def self.download_from_minio(file_key)
    s3_client = MinioClient.client
    obj = s3_client.bucket(ENV.fetch('DEFAULT_BUCKET', nil)).object(file_key)
    local_path = File.join('tmp', File.basename(file_key))
    FileUtils.mkdir_p('tmp') unless File.directory?('tmp')
    File.binwrite(local_path, obj.get.body.read)
    Rails.debugger.info "File downloaded: #{local_path}"
    local_path
  rescue StandardError => e
    Rails.debugger.info "Error downloading #{file_key}: #{e.message}"
  end
  
end
