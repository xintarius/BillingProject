  require 'rtesseract'
  require 'pdf-reader'
  require 'mini_magick'
  require 'pycall/import'
  require 'damerau-levenshtein'
  require 'open3'
  require 'fileutils'
  require 'fiddle'

  # Reader service
  class ReaderService

    include PyCall::Import
    CV2 = PyCall.import_module('cv2')
    NUMPY = PyCall.import_module('numpy')
    MAX_WIDTH = 2000
    MAX_HEIGHT = 4000
    PRECISION = 0.00001

    def self.send_file(file, company_id)
      today = Time.zone.now.strftime('%Y%m%d')
      invoice = Invoice.where(company_id: company_id).order(created_at: :desc).first
      extension = add_extension(file)
      filename = "#{company_id.nip}_#{today}_#{invoice.id}.#{extension}"

      if extension == 'pdf'
        extract_pdf_for_task(file)
      else
        file = ReaderService.convert_to_png_if_needed(file)
        extract_image_for_controller(file)
      end

      upload_minio(filename, file, invoice)
    end

    def self.upload_minio(filename, file, invoice)
      file_path = "uploads/#{filename}"
      invoice.update!(file_path: file_path)
      MinioClient.upload(file_path, file)
    end

    def self.extract_image_for_controller(file)
      temp_path = '/tmp/temp_image.jpg'
      invoices = Invoice.where(file_path: file_key, ocr_image_phase: nil)

      invoices.each do |invoice|
        ReaderService.read_nip_with_adaptation(reading_file(file), invoice.company&.nip, temp_path)
      end
    rescue StandardError => e
      puts "OCR image error: #{e.message}"
    end

    def self.read_nip_with_adaptation(file_path, expected_nip, tmp_path, invoice)
      puts "starting read nip with adaptation for file #{file_path}"
      best_result = nil
      best_ocr_fragment = []
      variants = preprocessing_options_cv.reject { |opts| opts[:rotate] }

      variants.each do |variant|
        result = try_variant(variant, file_path, expected_nip, tmp_path, best_ocr_fragment)
        next unless result

        best_result = result
        break
      end
      mark_invoice_nip_as_ended(invoice, best_result, expected_nip, best_ocr_fragment)

      best_result == expected_nip
    end



    def self.convert_to_png_if_needed(file)
      mime = Marcel::MimeType.for(Pathname.new(file.path))

      return file if mime == 'image/png'

      image = Vips::Image.new_from_file(file.path, access: :sequential)

      tempfile = Tempfile.new(['converted', '.png'])
      image.write_to_file(tempfile.path)
      tempfile
    end

    def self.extract_image_for_task(file, invoice)
      @resize_scale = compute_max_resize_scale(file)

      temp_input_path = "/tmp/original_ocr_image_#{SecureRandom.hex(4)}.png"
      temp_output_path = "/tmp/shared_temp_image_#{SecureRandom.hex(4)}.jpg"

      File.open(temp_input_path, 'wb') do |f|
        if file.respond_to?(:read)
          f.write(file.read)
        elsif file.is_a?(String) && File.exist?(file)
          f.write(File.read(file))
        else
          raise ArgumentError, "Unsupported file type: #{file.class}"
        end
      end

      result = ReaderService.read_nip_with_adaptation(temp_input_path, invoice.company&.nip, temp_output_path, invoice)
      puts "read_nip_with_adaptation result #{result}"
      invoice.update!(invoice_status: 'failed', description_error: 'Problem with the nip') unless result
    rescue StandardError => e
      puts "OCR image error: #{e.message}"
    end


    def self.reading_file(file)
      if file.is_a?(String) && File.exist?(file)
        yield file
      elsif file.respond_to?(:path) && File.exist?(file.path)
        yield file.path
      else
        Tempfile.open(%w[ocr_image .png]) do |tempfile|
          yield tempfile.path
        end
      end
    end

    def self.normalize_nip(nip)
      nip.to_s.gsub(/[^0-9]/, '')
    end

    def self.compare_nip(ocr, result, expected, best_ocr_fragment)
      return 0 if result.nil? || expected.nil?

      normalize_result = normalize_nip(result)
      normalize_expected = normalize_nip(expected)
      puts "normalize_result #{normalize_result} vs normalize_expected #{normalize_expected}"
      if normalize_result == normalize_expected
        best_ocr_fragment << ocr
        puts "[COMPARE_NIP] Normalized result: #{normalize_result.inspect}, expected: #{normalize_expected.inspect}"
        return 1.0
      end

      min_len = [normalize_result.length, normalize_expected.length].min
      return 0 if min_len < 8

      distance = DamerauLevenshtein.distance(normalize_result, normalize_expected)
      1.0 - (distance.to_f / normalize_expected.length)
    end

    def self.try_variant(variant, file_path, expected_nip, tmp_path, best_ocr_fragment)
      puts "Trying variant: #{variant.inspect} on file: #{file_path}"

      image = preprocess_image(variant, file_path, tmp_path)
      puts "IMAGE SET: #{image}"
      ocr_text = manage_tesseract(image)
      puts "[TESSERACT] output: #{ocr_text}"

      result = extract_and_fix(ocr_text, variant, expected_nip, best_ocr_fragment)
      return result if result

      puts "try variant #{result}"

      return nil unless extract_nip_candidates(ocr_text).empty?

      # Fallback OpenCV
      image = preprocess_with_opencv_py(variant, file_path)
      puts "[DEBUG] OpenCV returned path: #{image.inspect}"
      ocr_text = manage_tesseract(image)

      result = extract_and_fix(ocr_text, variant, expected_nip, best_ocr_fragment)
      return result if result

      puts "extract_and_fix result: #{result}"
      puts "[DEBUG] NIP candidates: #{extract_nip_candidates(ocr_text).inspect}"
      return nil if extract_nip_candidates(ocr_text).to_s.scan(/\d/).size >= 8

      get_candidate_nips(variant, expected_nip, file_path, tmp_path, best_ocr_fragment)
      puts "image deleted: #{image}"
    end

    def self.manage_tesseract(image)
      puts "[TESSERACT] input: #{image.inspect}"
      puts "[DEBUG] Image path: #{image.is_a?(MiniMagick::Image) ? image.path : image}"
      path = image.is_a?(MiniMagick::Image) ? image.path : image
      puts "PATH #{path}"
      start = RTesseract.new(path, lang: 'pol', options: { tessedit_char_whitelist: '0123456789' }).to_s
      puts "TESSERACT #{start}"
      start
    end

    def self.manage_mini_magick(tmp_path)
      MiniMagick::Image.open(tmp_path)
    end

    def self.preprocess_image(options = {}, file, tmp_path)
      puts "START PREPROCESS_IMAGE WITH OPTIONS: #{options}, FILE: #{file} AND TMP_PATH: #{tmp_path}"
      path = file.respond_to?(:path) ? file.path : file
      puts "THE PATH: #{path}"
      image = MiniMagick::Image.open(path).clone
      puts "IMAGE: #{image}"
      set_mini_magick_options(image, options)
      puts "MINIMAGICK OPTIONS: #{set_mini_magick_options(image, options)}"
      image.write(tmp_path)
      manage_mini_magick(tmp_path)
    rescue StandardError => e
      puts "[MiniMagick failed: #{e.message}] → Falling back to OpenCV"
      preprocess_with_opencv_py(options, file)
    end

    def self.preprocess_with_opencv_py(options = {}, file)
      @cv2 = CV2
      @numpy = NUMPY

      puts "[OpenCV] Reading image from: #{file}"

      img = @cv2.imread(file.to_s, @cv2.IMREAD_GRAYSCALE)
      img = resize_image_opencv(img)
      puts "[OpenCV] Original image shape: #{img.shape}"

      img_option = use_img_options(@cv2, img, options, @numpy)

      tmp_path = "#{Dir.tmpdir}/opencv_py_preprocessed_#{SecureRandom.hex}.png"
      @cv2.imwrite(tmp_path, img_option)
      puts "[OpenCV] Saved preprocessed image to: #{tmp_path}"

      MiniMagick::Image.open(tmp_path)
    end

    def self.resize_image_opencv(image)
      @cv2 = CV2
      height = image.shape[0]
      width = image.shape[1]

      scale = [MAX_WIDTH.to_f / width, MAX_HEIGHT.to_f / height, 2.0].min
      if scale < 1.0
        new_width = (width * scale).round
        new_height = (height * scale).round
        resized = @cv2.resize(image, [new_width, new_height])
        puts "[OpenCV] Resized image from (#{width}, #{height}) to (#{new_width}, #{new_height})"
        resized
      else
        image
      end
    end

    def self.set_mini_magick_options(image, options)
      image.colorspace 'Gray'
      image.density(300)
      image.normalize
      image.level '10%,90%'
      image.sharpen '0x2' if options.fetch(:sharpen, true)
      image.contrast if options.fetch(:contrast, true)
      image.morphology 'Close', 'Diamond:1'
      image.threshold '40%' if options.fetch(:threshold, true)
      image.rotate options[:rotate] if options[:rotate]
      image.resize options[:resize] if options[:resize]
    end

    def self.extract_and_fix(ocr, variant, expected_nip, best_ocr_fragment)
      extract_nip_candidates(ocr).each do |candidate|
        fixed = fix_common_ocr_errors(ocr, candidate, expected_nip, best_ocr_fragment)
        next if fixed.nil?

        score = compare_nip(ocr, fixed, expected_nip, best_ocr_fragment)
        puts "Get nip: #{fixed} from variant: #{variant.inspect}"
        return fixed if (score - 1.0).abs < PRECISION
      end
      nil
    end

    def self.mark_invoice_nip_as_ended(invoice, result_nip, expected_nip, best_ocr_fragment)
      return if invoice.ocr_image_phase == 'nip_step_completed'

      if result_nip != expected_nip
        invoice.update!(
          description_error: result_nip || 'NIP not found',
          invoice_status: 'failed',
          ocr_image_phase: 'nip_step_completed' # <-- to dodaj nawet przy błędzie!
        )
        puts 'ocr not completed, there are problems with the image reading'
        return
      end

      invoice.update!(
        ocr_image_phase: 'nip_step_completed',
        invoice_status: 'success',
        invoice_data: best_ocr_fragment
      )
    end


    def self.get_candidate_nips(variant, expected_nip, file_path, tmp_path, best_ocr_fragment)
      puts "[DEBUG] get_candidate_nips CALLED with file: #{file_path}"

      variants = mutate_variant(variant)
      puts "[DEBUG] Mutated variants: #{variants.inspect}"

      variants.each do |mutate|
        puts "[DEBUG] Trying mutated variant: #{mutate.inspect}"
        image = preprocess_image(mutate, file_path, tmp_path)
        text = manage_tesseract(image)
        puts "[DEBUG] OCR result for mutated variant: #{text.inspect}"

        result = extract_nips(text, mutate, expected_nip, best_ocr_fragment)
        puts "[DEBUG] extract_nips result: #{result.inspect}"
        return result if result
      end

      puts "[DEBUG] No valid NIP found in mutated variants."
      nil
    end


    def self.extract_nips(ocr, mutate, expected_nip, best_ocr_fragment)
      extract_nip_candidates(ocr).each do |candidate|
        fixed = fix_common_ocr_errors(ocr, candidate, expected_nip, best_ocr_fragment)
        next if fixed.nil?

        score = compare_nip(ocr, fixed, expected_nip, best_ocr_fragment)
        puts "Get nip: #{fixed} from variant: #{mutate.inspect}"
        if (score - 1.0).abs < PRECISION
          @found_valid_nip = true
          return fixed
        end
      end
      nil
    end

    def self.compute_max_resize_scale(file)
      image = MiniMagick::Image.open(file)
      width = image.width
      height = image.height

      scale_x = MAX_WIDTH.to_f / width
      scale_y = MAX_HEIGHT.to_f / height

      [scale_x, scale_y, 2.0].min
    end

    def self.fix_common_ocr_errors(ocr, nip, expected_nip, best_ocr_fragment)
      puts "fix common errors nip: #{nip}"
      return nil if nip.nil?

      nip = nip.gsub(/\D/, '')

      return nil if nip.length < 8 || nip.length > 11

      candidates = [nip]
      candidates.uniq!

      select_best_candidate(ocr, candidates, expected_nip, best_ocr_fragment)
    end

    def self.select_best_candidate(ocr, candidates, expected_nip, best_ocr_fragment)
      best = candidates
               .select { |c| c.length == expected_nip.length }
               .max_by { |candidate| compare_nip(ocr, candidate, expected_nip, best_ocr_fragment) }

      score = compare_nip(ocr, best, expected_nip, best_ocr_fragment)
      best if (score - 1.0).abs < PRECISION
    end

    def self.preprocessing_options
      [
        { contrast: true },
        { grayscale: true, sharpen: true },
        { grayscale: true, threshold: true },
        { rotate: 90 },
        { rotate: 270, contrast: true },
        { resize: '150%' },
        { grayscale: true, contrast: true, sharpen: true },
      ]
    end

    def self.mutate_variant(base_variant, limit: 2)
      mutations = []
      mutations << base_variant.merge(sharpen: true) unless base_variant[:sharpen]
      mutations << base_variant.merge(threshold: true) unless base_variant[:threshold]
      mutations << base_variant.merge(contrast: true) unless base_variant[:contrast]
      mutations << base_variant.merge(resize: '150%') unless base_variant[:resize]
      mutations.uniq.first(limit)
    end

    def self.use_img_options(cv2, img, options, numpy)
      img = rotate_image(cv2, img, options[:rotate])
      img = resize_image(cv2, img, options[:resize])
      img = denoise_image(cv2, img) if options[:denoise]
      img = blur_image(cv2, img, options[:blur]) if options[:blur]
      img = morphology_image(cv2, img, options)
      img = sharpen_image(cv2, numpy, img) if options[:sharpen]
      img = adjust_contrast(cv2, img, options) if options[:contrast_alpha] || options[:contrast_beta]
      img = treshold_image(cv2, img, options)
      apply_clahe(cv2, img)
    end

    def self.apply_clahe(cv2, img)
      puts '[OpenCV] Applying CLAHE'
      clahe = cv2.createCLAHE(2.0, [8, 8])
      clahe.apply(img)
    end

    def self.treshold_image(cv2, img, options)
      if options[:adaptive_threshold]
        puts '[OpenCV] Applying adaptiveThreshold'
        cv2.adaptiveThreshold(img, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
                              cv2.THRESH_BINARY, 11, 2)
      elsif options[:threshold]
        puts '[OpenCV] Applying simple threshold'
        _, img = cv2.threshold(img, 127, 255, cv2.THRESH_BINARY)
      end
      img
    end

    def self.adjust_contrast(cv2, img, options)
      alpha = options[:contrast_alpha] || 1.5
      beta = options[:contrast_beta] || 20
      puts "[OpenCV] Adjusting contrast with alpha: #{alpha}, beta: #{beta}"
      cv2.convertScaleAbs(img, alpha, beta)
    end

    def self.sharpen_image(cv2, numpy, img)
      puts '[OpenCV] Applying sharpening filter'
      kernel = numpy.array([[0, -1, 0], [-1, 5, -1], [0, -1, 0]])
      cv2.filter2D(img, -1, kernel)
    end

    def self.morphology_image(cv2, img, options)
      kernel_morph = cv2.getStructuringElement(cv2.MORPH_RECT, [3, 3])

      if options[:morph_close]
        puts '[OpenCV] Applying morphologyEx - Close'
        img = cv2.morphologyEx(img, cv2.MORPH_CLOSE, kernel_morph)
      end

      if options[:dilate]
        puts "[OpenCV] Dilating image, iterations: #{options[:dilate]}"
        img = cv2.dilate(img, kernel_morph, options[:dilate])
      end

      if options[:erode]
        puts "[OpenCV] Eroding image, iterations: #{options[:erode]}"
        img = cv2.erode(img, kernel_morph, options[:erode])
      end
      img
    end

    def self.blur_image(cv2, img, blur_value)
      blur_value ||= 3
      puts "[OpenCV] Applying GaussianBlur with kernel size: #{blur_value}x#{blur_value}"
      cv2.GaussianBlur(img, [blur_value, blur_value], 0)
    end

    def self.denoise_image(cv2, img)
      puts '[OpenCV] Applying fastNlMeansDenoising'
      cv2.fastNlMeansDenoising(img, nil, 10)
    end

    def self.resize_image(cv2, img, scale)
      return img unless scale

      scale = 2.0 if scale == true
      puts "[OpenCV] Resizing image with scale factor: #{scale}"
      resized = cv2.resize(img, nil, scale, scale, cv2.INTER_CUBIC)
      puts "[OpenCV] Resized image shape: #{resized.shape}"
      resized
    end

    def self.rotate_image(cv2, img, angle)
      case angle
      when 90
        puts '[OpenCV] Rotating image 90 degrees clockwise'
        cv2.rotate(img, cv2.ROTATE_90_CLOCKWISE)
      when 270
        puts '[OpenCV] Rotating image 270 degrees clockwise (or 90 counterclockwise)'
        cv2.rotate(img, cv2.ROTATE_90_COUNTERCLOCKWISE)
      end
      img
    end

    def self.preprocessing_options_cv
      base_variants = [
        {}, # without options
        { contrast_alpha: 1.5, contrast_beta: 20 },
        { threshold: true },
        { adaptive_threshold: true },
        { blur: 3 },
        { dilate: 1 },
        { erode: 1 },
        { resize: @resize_scale },
        { denoise: true },
        { sharpen: true },
        { morph_close: true },
        { clahe: true }
      ]

      resize_scales = [0.85, 1.0, 1.15, 1.3]
      resize_variants = resize_scales.map { |s| { resize: s } }

      (base_variants + resize_variants).uniq
    end

    def self.rotated_variants(base_variants)
      rotated_variants = base_variants.map { |opts| opts.merge(rotate: 90) }
      rotated_more = base_variants.map { |opts| opts.merge(rotate: 270) }

      base_variants + rotated_variants + rotated_more
    end

    def self.extract_nip_candidates(ocr_text)
      puts "Extracting NIP candidates from OCR text: #{ocr_text.inspect}"
      return [] unless ocr_text

      matches = []
      matches += ocr_text.scan(/\b(?:\d{2,4}[-\s]?){2,5}\d{2,4}\b/)
      matches += ocr_text.scan(/\b\d{10}\b/)

      candidates = matches.map do |raw|
        cleaned = raw.gsub(/[^0-9]/, '')
        next if cleaned.length != 10 || cleaned.start_with?('0000')

        cleaned
      end
      candidates.compact.uniq
    end
  end
