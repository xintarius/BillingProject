# Reader service
class ReaderService

  def self.send_file(file, company_id)
    today = Time.zone.now.strftime('%Y%m%d')
    invoice = Invoice.where(company_id: company_id).order(created_at: :desc).first
    extension = add_extension(file)
    filename = "#{company_id.nip}_#{today}_#{invoice.id}.#{extension}"
    upload_minio(filename, file, invoice)
  end

  def self.add_extension(file)
    case file.content_type
    when 'application/pdf' then 'pdf'
    when 'image/jpeg' then 'jpeg'
    when 'image/jpg' then 'jpg'
    when 'image/png' then 'png'
    else
      StandardError
    end
  end

  def self.upload_minio(filename, file, invoice)
    file_path = "uploads/#{filename}"
    invoice.update!(file_path: file_path)
    MinioClient.upload(file_path, file)
  end

  # save the method for changing plans
  def self.mark_invoice_nip_as_ended(invoice, result_nip, expected_nip, best_ocr_fragment)
    return if invoice.ocr_image_phase == 'nip_step_completed'

    if result_nip != expected_nip
      invoice.update!(
        description_error: result_nip || 'NIP not found',
        invoice_status: 'failed',
        ocr_image_phase: 'nip_step_completed' # <-- to dodaj nawet przy błędzie!
      )
      puts "#{DateTime.now}: ocr not completed, there are problems with the image reading"
      return
    end

    invoice.update!(
      ocr_image_phase: 'nip_step_completed',
      invoice_status: 'success',
      invoice_data: best_ocr_fragment
    )
  end
end
