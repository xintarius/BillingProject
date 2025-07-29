require 'mini_magick'
require 'rtesseract'
require 'pycall/import'
require 'damerau-levenshtein'
require 'open3'
# app/services/ocr/image_nip_reader.rb
class ImageNipReader

  include PyCall::Import

  attr_reader :image_path, :expected_nip

  MAX_WIDTH = 1500
  MAX_HEIGHT = 2500
  PRECISION = 0.00001

  IGNORED_NIPS = ENV["IGNORED_NIP"].freeze

  def initialize(image_path, expected_nip)
    @image_path = image_path
    @expected_nip = expected_nip
    @resize_scale = compute_max_resize_scale
  end

  def self.normalize_nip(nip)
    nip.to_s.gsub(/[^0-9]/, '')
  end

  def self.compare_nip(result, expected)
    return 0 if result.nil? || expected.nil?

    normalize_result = normalize_nip(result)
    normalize_expected = normalize_nip(expected)

    return 1.0 if normalize_result == normalize_expected

    min_len = [normalize_result.length, normalize_expected.length].min
    return 0 if min_len < 8

    distance = DamerauLevenshtein.distance(normalize_result, normalize_expected)
    1.0 - (distance.to_f / normalize_expected.length)
  end

  def read_nip_with_adaptation
    variants = preprocessing_options_cv.reject { |opts| opts[:rotate] }

    variants.each do |variant|
      try_variant(variant)
    end
    puts "can't read nip from the image"
    nil
  end

  private

  def try_variant(variant)
    image = preprocess_image(variant)
    ocr = RTesseract.new(image.path, lang: 'pol', options: { tessedit_char_whitelist: '0123456789' }).to_s
    extract_and_fix(ocr, variant)

    # Fallback OpenCV
    return unless extract_nip_candidates(ocr).empty?

    image = preprocess_with_opencv_py(variant)
    ocr = RTesseract.new(image.path, lang: 'pol', options: { tessedit_char_whitelist: '0123456789' }).to_s
    extract_and_fix(ocr, variant)
    get_candidate_nips(extract_nip_candidates(ocr), variant)
  end

  def extract_and_fix(ocr, variant)
    extract_nip_candidates(ocr).each do |candidate|
      fixed = fix_common_ocr_errors(candidate)
      next if fixed.nil? || IGNORED_NIPS.include?(fixed)

      score = self.class.compare_nip(fixed, expected_nip)
      puts "Get nip: #{fixed} from variant: #{variant.inspect}"
      return fixed if (score - 1.0).abs < PRECISION
    end
  end

  def get_candidate_nips(nip_candidates, variant)
    return if nip_candidates.to_s.scan(/\d/).size >= 8

    mutate_variant(variant).each do |mutate|
      image = preprocess_image(mutate)
      ocr = RTesseract.new(image.path, lang: 'pol', options: { tessedit_char_whitelist: '0123456789' }).to_s

      extract_nips(ocr, mutate)
    end
  end

  def extract_nips(ocr, mutate)
    extract_nip_candidates(ocr).each do |candidate|
      fixed = fix_common_ocr_errors(candidate)
      next if fixed.nil? || IGNORED_NIPS.include?(fixed)

      score = self.class.compare_nip(fixed, expected_nip)

      puts "Get nip: #{fixed} from variant: #{mutate.inspect}"
      return fixed if (score - 1.0).abs < PRECISION
    end
  end

  def compute_max_resize_scale
    image = MiniMagick::Image.open(image_path)
    width = image.width
    height = image.height

    scale_x = MAX_WIDTH.to_f / width
    scale_y = MAX_HEIGHT.to_f / height

    [scale_x, scale_y, 2.0].min
  end

  def fix_common_ocr_errors(nip)
    puts "fix common errors nip: #{nip}"
    return nil if nip.nil?

    nip = nip.gsub(/\D/, '')

    return nil if nip.length < 8 || nip.length > 11

    candidates = [nip]
    candidates.uniq!

    select_best_candidate(candidates)
  end

  def select_best_candidate(candidates)
    best = candidates
             .select { |c| c.length == expected_nip.length }
             .max_by { |candidate| self.class.compare_nip(candidate, expected_nip) }

    best_score = self.class.compare_nip(best, expected_nip)
    best_score >= 1.0 ? best : nil
  end

  def resize_image_opencv(image)
    pyimport 'cv2'

    height = image.shape[0]
    width = image.shape[1]

    scale = [MAX_WIDTH.to_f / width, MAX_HEIGHT.to_f / height, 1.0].min
    if scale < 1.0
      new_width = (width * scale).round
      new_height = (height * scale).round
      resized = cv2.resize(image, [new_width, new_height])
      puts "[OpenCV] Resized image from (#{width}, #{height}) to (#{new_width}, #{new_height})"
      resized
    else
      image
    end
  end

  def preprocessing_options
    [
      {},
      { contrast: true },
      { grayscale: true, sharpen: true },
      { grayscale: true, threshold: true },
      { rotate: 90 },
      { rotate: 270, contrast: true },
      { resize: '150%' },
      { grayscale: true, contrast: true, sharpen: true },
    ]
  end

  def mutate_variant(base_variant, limit: 2)
    mutations = []
    mutations << base_variant.merge(sharpen: true) unless base_variant[:sharpen]
    mutations << base_variant.merge(threshold: true) unless base_variant[:threshold]
    mutations << base_variant.merge(contrast: true) unless base_variant[:contrast]
    mutations << base_variant.merge(resize: '150%') unless base_variant[:resize]
    mutations.uniq.first(limit)
  end

  def preprocess_image(options = {})
    image = MiniMagick::Image.open(image_path).clone
    set_mini_magick_options(image, options)
    tmp_path = "#{Dir.tmpdir}/tmp_nip_#{SecureRandom.hex}.png"
    image.write(tmp_path)
    MiniMagick::Image.open(tmp_path)
  rescue StandardError => e
    puts "[MiniMagick failed: #{e.message}] → Falling back to OpenCV"
    preprocess_with_opencv_py
  end

  def set_mini_magick_options(image, options)
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

  def preprocess_with_opencv_py(options = {})
    cv2 = PyCall.import_module('cv2')
    numpy = PyCall.import_module('numpy')

    puts "[OpenCV] Reading image from: #{image_path}"
    img = cv2.imread(image_path.to_s, cv2.IMREAD_GRAYSCALE)
    img = resize_image_opencv(img)
    puts "[OpenCV] Original image shape: #{img.shape}"

    img_option = use_img_options(cv2, img, options, numpy)

    tmp_path = "#{Dir.tmpdir}/opencv_py_preprocessed_#{SecureRandom.hex}.png"
    cv2.imwrite(tmp_path, img_option)
    puts "[OpenCV] Saved preprocessed image to: #{tmp_path}"

    MiniMagick::Image.open(tmp_path)
  end

  def use_img_options(cv2, img, options, numpy)
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

  def apply_clahe(cv2, img)
    puts '[OpenCV] Applying CLAHE'
    clahe = cv2.createCLAHE(2.0, [8, 8])
    clahe.apply(img)
  end

  def treshold_image(cv2, img, options)
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

  def adjust_contrast(cv2, img, options)
    alpha = options[:contrast_alpha] || 1.5
    beta = options[:contrast_beta] || 20
    puts "[OpenCV] Adjusting contrast with alpha: #{alpha}, beta: #{beta}"
    cv2.convertScaleAbs(img, alpha, beta)
  end

  def sharpen_image(cv2, numpy, img)
    puts '[OpenCV] Applying sharpening filter'
    kernel = numpy.array([[0, -1, 0], [-1, 5, -1], [0, -1, 0]])
    cv2.filter2D(img, -1, kernel)
  end

  def morphology_image(cv2, img, options)
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

  def blur_image(cv2, img, blur_value)
    blur_value ||= 3
    puts "[OpenCV] Applying GaussianBlur with kernel size: #{blur_value}x#{blur_value}"
    cv2.GaussianBlur(img, [blur_value, blur_value], 0)
  end

  def denoise_image(cv2, img)
    puts '[OpenCV] Applying fastNlMeansDenoising'
    cv2.fastNlMeansDenoising(img, nil, 10)
  end

  def resize_image(cv2, img, scale)
    return img unless scale

    scale = 2.0 if scale == true
    puts "[OpenCV] Resizing image with scale factor: #{scale}"
    resized = cv2.resize(img, nil, scale, scale, cv2.INTER_CUBIC)
    puts "[OpenCV] Resized image shape: #{resized.shape}"
    resized
  end

  def rotate_image(cv2, img, angle)
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

  def preprocessing_options_cv
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
    rotated_variants(base_variants)
  end

  def rotated_variants(base_variants)
    rotated_variants = base_variants.map { |opts| opts.merge(rotate: 90) }
    rotated_more = base_variants.map { |opts| opts.merge(rotate: 270) }

    base_variants + rotated_variants + rotated_more
  end

  def extract_nip_candidates(ocr_text)
    return [] unless ocr_text

    matches = ocr_text.scan(/\b(?:\d{3}[- ]?\d{2}[- ]?\d{2}[- ]?\d{3}|\d{10})\b/)

    candidates = matches.map do |raw|
      cleaned = raw.gsub(/[^0-9]/, '')
      next if cleaned.start_with?('0000') || cleaned.size != 10

      cleaned
    end
    candidates.compact.uniq
  end
end
