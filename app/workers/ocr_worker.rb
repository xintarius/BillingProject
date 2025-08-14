# ocr_worker
class OcrWorker
  include Sidekiq::Worker
  sidekiq_options queue: :ocr, retry: 3, lock_args: ->(args) { [args] }

  def perform(file_key)
    puts "#{DateTime.now}: 📥 Download file: #{file_key}"

    file_content = MinioClient.get_object(file_key)

    if file_key.end_with?('.pdf')
      Tempfile.open(%w[ocr_input .pdf]) do |tempfile|
        tempfile.binmode
        tempfile.write(file_content)
        tempfile.rewind
        ReaderService.extract_pdf_for_task(tempfile.path)
      end
    else
      Tempfile.open(['ocr_input', '.tmp']) do |tempfile|
        tempfile.binmode
        tempfile.write(file_content)
        tempfile.rewind
        mime = Marcel::MimeType.for(tempfile)

        puts "#{DateTime.now}: Detected MIME: #{mime}"

        original = Tempfile.new(['ocr_input', self.class.mime_extension(mime)])
        original.binmode
        original.write(file_content)
        original.rewind

        #converted = ReaderService.convert_to_png_if_needed(original)

        invoice = Invoice.find_by(file_path: file_key)
        ReaderService.extract_image_for_task(original.path, invoice, mime)

        # converted.close
        # converted.unlink
        original.close
        original.unlink
      end
    end
  rescue StandardError => e
    puts "#{DateTime.now}: Ocr error for #{file_key}: #{e.message}"
  end

  def self.mime_extension(mime)
    case mime
    when 'image/jpeg' then '.jpeg'
    when 'image/jpg' then '.jpg'
    when 'image/png'  then '.png'
    when 'image/tiff' then '.tiff'
    else '.img'
    end
  end
end
