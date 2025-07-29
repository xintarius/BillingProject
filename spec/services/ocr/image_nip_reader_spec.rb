# spec/lib/image_nip_reader_spec.rb
require 'rails_helper'
require_relative '../../../app/services/ocr/image_nip_reader'
RSpec.describe ImageNipReader do
  let(:image_path) { Rails.root.join("spec/fixtures/files/#{ENV['IMAGE_PATH']}") }
  let(:expected_nip) { ENV["EXPTECTED_NIP"] }

  it 'Reading a nip from the image test' do
    reader = ImageNipReader.new(image_path, expected_nip)
    result = reader.read_nip_with_adaptation

    expect(ImageNipReader.compare_nip(result, expected_nip)).to eq(1.0)
    puts result
  end
end
