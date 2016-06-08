require 'open-uri' 
require 'nokogiri'
require 'parallel'
require 'open_uri_redirections'
require 'fileutils'
require 'yaml'

class ImageDownloader

  CONFIG_FILE = 'config.yml'

  def self.download_images(url)
    config = Config.new(CONFIG_FILE)
    path = config.download_folder
    url = Url.validate_scheme(url)
    html = Fetcher.fetch_file(url)
    image_urls = Parser.image_urls(html)

    image_urls.map! { |image_url| Url.to_absolute(image_url, url) }

    FileUtils.mkdir_p(path)

    Parallel.each(image_urls, :in_threads => 5) do |img_url|
      image = Fetcher.fetch_file(img_url)

      Writer.write_file(image, Url.file_name(img_url), path)
    end
  end

  class Url

    def self.validate_scheme(url)
      url = URI(url)

      url.scheme.nil? ? "http://#{url}" : url.to_s
    end

    def self.to_absolute(url,host)
      host_url = URI(host)
      scheme = host_url.scheme
      url_with_scheme = "#{scheme}://#{host_url.host}"

      case url
        when /^\/\/\S*/i
          "#{scheme}:#{url}"
        when /^\/?S*/i && /^(?!http:\/\/).*/ie
          URI.join(url_with_scheme, url).to_s
        else
          url
      end
    end

    def self.file_name(url)
      name = URI(url).path.to_s.split("/").last

      name.length < 50 ? name : "#{name.slice(0..50)}..#{File.extname(name)}"
    end
  end

  class Config

    DEFAULT_CONFIG = {
        download_folder: 'downloaded_images'
    }

    def initialize(config_file)
      @config = load_config(config_file)

      initialize_methods
    end

    private

      def initialize_methods
        DEFAULT_CONFIG.each do |k, v|
          self.define_singleton_method(k) do
            @config[k] || v
          end
        end
      end

      def load_config(config_file)
        File.open(config_file, "w") {|f| f.write(DEFAULT_CONFIG.to_yaml) } unless File.file?(config_file)

        YAML.load(File.open(config_file))
      end
  end


  class Fetcher

    def self.fetch_file(url)
      open(url, :allow_redirections => :safe)
    rescue SocketError, OpenURI::HTTPError => error
      puts "can't open #{url} (#{error})"
    end
  end

  class Parser

    def self.image_urls(html)
      html = Nokogiri::HTML(html)
      image_urls = html.xpath("//img/@src").to_a

      image_urls.uniq!
      puts "found #{image_urls.count} images"

      image_urls
    end
  end

  class Writer

    def self.write_file(file, name, path)
      fullpath = "#{path}/#{name}"

      if File.file?(fullpath)
        print "file #{name} already exists, write to "
        name = "_#{name}"
        print "#{name} \n"

        write_file(file, name, path)
      else
        IO.copy_stream(file, "#{fullpath}")
      end
    rescue IOError
      puts "can't write #{fullpath} (#{e})"
    end
  end
end

if ARGV[0]
  ImageDownloader.download_images(ARGV[0])
else
  puts "use image_downloader.rb [url]"
end

