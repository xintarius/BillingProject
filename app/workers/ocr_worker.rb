# app/workers/ocr_worker.rb
class OcrWorker
  include Sidekiq::Worker
  sidekiq_options queue: :ocr, retry: 3

  MAX_FILE_SIZE = 5 * 1024 * 1024  # 5 MB

  def perform(file_key)
    puts "#{DateTime.now}: 📥 Download file: #{file_key}"

    file_content = MinioClient.get_object(file_key)
    file_content = resize_image_if_needed(file_content)

    if file_content.bytesize > MAX_FILE_SIZE
      puts "❌ File still too large after resize: #{file_content.bytesize}B"
      invoice = Invoice.find_or_initialize_by(file_path: file_key)
      invoice.update!(
        ocr_image_phase: 'too_large',
        invoice_data: { "error" => "File exceeds size limit after resize" }
      )
      return
    end

    # wysyłka do Azure
    response = HTTParty.post(
      "#{endpoint}/formrecognizer/documentModels/prebuilt-read:analyze?api-version=#{api_version}",
      headers: {
        "Ocp-Apim-Subscription-Key" => api_key,
        "Content-Type" => content_type(file_key)
      },
      body: file_content
    )

    if response.code == 202
      parsed = poll_until_done(response.headers["operation-location"])
    elsif response.code == 200
      parsed = JSON.parse(response.body)
    else
      invoice = Invoice.find_or_initialize_by(file_path: file_key)
      invoice.update!(ocr_image_phase: 'to_large')
    end

    # zapis wyniku
    invoice = Invoice.find_or_initialize_by(file_path: file_key)
    invoice.update!(
      ocr_image_phase: "done",
      invoice_data: parsed
    )

    puts "#{DateTime.now}: ✅ OCR saved for #{file_key}"

  rescue => e
    invoice = Invoice.find_or_initialize_by(file_path: file_key)
    invoice.update!(
      ocr_status: "error",
      invoice_data: { "error" => e.message }
    )
    puts "#{DateTime.now}: ❌ OCR error for #{file_key}: #{e.message}"
  end

  private

  def content_type(file_key)
    case File.extname(file_key).downcase
    when ".png" then "image/png"
    when ".jpg", ".jpeg" then "image/jpeg"
    else "application/octet-stream"
    end
  end

  def resize_image_if_needed(file_content)
    return file_content if file_content.bytesize <= MAX_FILE_SIZE

    image = MiniMagick::Image.read(file_content)
    while image.to_blob.bytesize > MAX_FILE_SIZE
      image.resize "80%"
      image.quality 80 if image.type.downcase == "jpeg"
    end
    image.to_blob
  end

  def poll_until_done(operation_location)
      loop do
        response = HTTParty.get(
          operation_location,
          headers: { 'Ocp-Apim-Subscription-Key' => api_key }
        )
        parsed = JSON.parse(response.body)

        case parsed['status']
        when 'succeeded'
          return parsed
        when 'failed'
          raise "Azure OCR async operation failed: #{parsed}"
        else
          sleep POLL_INTERVAL
        end
      end
    end

  def endpoint
    ENV.fetch('AZURE_RECEIPT_ENDPOINT')
  end

  def api_key
    ENV.fetch('AZURE_API_KEY')
  end

  def api_version
    '2023-07-31'
  end
end
