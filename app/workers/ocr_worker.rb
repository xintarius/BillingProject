# ocr_worker
class OcrWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: 3
  def perform(file_key)
    Rails.debugger.info "📥 Download file: #{file_key}"

    file_content = MinioClient.get_object(file_key)

    if file_key.end_with?('.pdf')
      Tempfile.open(%w[ocr_input .pdf]) do |tempfile|
        tempfile.binmode
        tempfile.write(file_content)
        tempfile.rewind
        ReaderService.extract_text_from_pdf(tempfile.path)
      end
    else
      tempfile = Tempfile.new(%w[ocr_input .jpg])
      tempfile.binmode
      tempfile.write(file_content)
      tempfile.rewind
      ReaderService.extract_text_from_image(tempfile.path, file_key)
      tempfile.close
      tempfile.unlink
    end
  rescue StandardError => e
    Rails.debugger.info "Ocr error for #{file_key}: #{e.message}"
  end
end
