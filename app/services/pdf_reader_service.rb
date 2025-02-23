# feature
# # pdf_reader_service
# require 'mini_magick'
# require 'tesseract-ocr'
# require 'pdf-reader'
#
# class PdfReaderService
#   def initialize(file)
#     @file = file
#   end
#
#   def get_text_from_pdf
#     reader = PDF::Reader.new(@file)
#     reader.pages.map(&:text).join("\n")
#   end
# end
