require 'rspec'
require './image_downloader.rb'

TEST_DIR = "#{Dir.pwd}/image_downloader_test"

def directory_files(dir)
  files = Dir.glob("#{dir}/**/*").reject{ |f| File.directory? f }
  files.map! { |f| File.basename(f) }
end