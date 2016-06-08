require 'spec_helper'

describe ImageDownloader::Url do

  let(:url) { "http://example.com/images/example.png" }
  let(:url_with_params) { "http://example.com/images/example.png?params" }
  let(:url_without_scheme) { "example.com/images/example.png" }
  let(:url_relative) { "/images/example.png" }
  let(:long_url) { "http://example.com/assets/#{'a'*60}.jpg" }

  it 'validates url scheme' do
    expect(ImageDownloader::Url.validate_scheme(url_without_scheme)).to eql url
  end

  it 'converts url to absolute' do
    expect(ImageDownloader::Url.to_absolute(url_relative,url)).to eql url
  end

  it 'gets image name' do
    expect(ImageDownloader::Url.file_name(url)).to eql "example.png"
  end

  it 'slices params from url' do
    expect(ImageDownloader::Url.file_name(url_with_params)).to eql "example.png"
  end

  it 'slices name if its too long' do
    expect(ImageDownloader::Url.file_name(long_url).size).to be < 60
  end
end

describe ImageDownloader::Parser do

  let(:html) { File.open("#{Dir.pwd}/spec/files/html_with_images.html") }

  it 'gets image urls' do
    expect(ImageDownloader::Parser.image_urls(html).size).to eql 3
  end
end

describe ImageDownloader::Parser do

  let(:html) { File.open("#{Dir.pwd}/spec/files/html_with_images.html") }

  it 'gets image urls' do
    expect(ImageDownloader::Parser.image_urls(html).size).to eql 3
  end
end

describe ImageDownloader::Writer do

  before(:all) do
    FileUtils.mkdir_p(TEST_DIR)
  end

  after(:all) { FileUtils.rm_rf(TEST_DIR) }

  let(:image) { File.open("#{Dir.pwd}/spec/files/test_image.gif") }

  it 'writes file' do
    ImageDownloader::Writer.write_file(image, "test_image.gif", TEST_DIR)
    expect(directory_files(TEST_DIR)).to include("test_image.gif")
  end

  it 'renames file if exist' do
    ImageDownloader::Writer.write_file(image, "test_image.gif", TEST_DIR)
    expect(directory_files(TEST_DIR).count).to eql 2
  end
end