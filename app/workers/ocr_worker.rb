# ocr_worker
class OcrWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: 3
  def perform(file_keys)
    file_keys.each do |file_key|
      begin
        puts "📥 Download file: #{file_key}"

        file_content = MinioClient.get_object(file_key)

        if file_key.end_with?('.pdf')
          Tempfile.open(%w[ocr_input .pdf]) do |tempfile|
            tempfile.binmode
            tempfile.write(file_content)
            tempfile.rewind
            ReaderService.extract_pdf_for_task(tempfile.path)
          end
        else
          mime = Marcel::MimeType.for(file_content, name: 'input.jpg')

          original = Tempfile.new(['ocr_input', self.class.mime_extension(mime)])
          original.binmode
          original.write(file_content)
          original.rewind

          converted = ReaderService.convert_to_png_if_needed(original)

          invoice = Invoice.find_by(file_path: file_key)
          ReaderService.extract_image_for_task(converted.path, invoice)

          converted.close
          converted.unlink
          original.close
          original.unlink
        end
      rescue StandardError => e
        puts "Ocr error for #{file_key}: #{e.message}"
      end
    end
  end

  def self.mime_extension(mime)
    case mime
    when 'image/jpeg' then '.jpg'
    when 'image/png'  then '.png'
    when 'image/tiff' then '.tif'
    else '.img'
    end
  end
end
