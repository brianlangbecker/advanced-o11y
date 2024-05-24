require 'sinatra'
require 'json'
require 'net/http'
require 'uri'
require 'open-uri'
require 'mini_magick'
require 'logger'

# Set up the logger to output to stdout
configure do
  set :port, 10114
  set :logger, Logger.new(STDOUT)
  settings.logger.level = Logger::INFO
end

helpers do
  def logger
    settings.logger
  end
end

# Health check endpoint
get '/health' do
  'OK'
end

# Endpoint to list available fonts (for debugging purposes)
get '/available_fonts' do
  fonts = `convert -list font`
  content_type :text
  fonts
end

post '/applyPhraseToPicture' do
  content_type :json
  input = JSON.parse(request.body.read)
  input_phrase = input['phrase']
  image_url = input['imageUrl']
  phrase = input_phrase.upcase

  begin
    logger.info "Received phrase: #{input_phrase}"
    logger.info "Received image URL: #{image_url}"
    logger.info "Converted phrase to uppercase: #{phrase}"

    # download the image, defaulting to a local image
    input_image_path = download(image_url)
    logger.info "Downloaded image to: #{input_image_path}"

    if FeatureFlags.new.use_library?
      output_buffer = apply_text_with_library(input_image_path, phrase)
      content_type 'image/png'
      logger.info "Applied text to image using library"
      return output_buffer
    else
      output_image_path = apply_text_with_imagemagick(phrase, input_image_path)
      logger.info "Applied text to image using ImageMagick"
      send_file output_image_path, type: 'image/png'
    end

  rescue => e
    status 500
    body 'Internal Server Error'
    STDERR.puts "Error creating picture: #{e.message}"
    logger.error "Error creating picture: #{e.message}"
  end
end

def download(image_url)
  uri = URI.parse(image_url)
  filename = File.join(Dir.tmpdir, File.basename(uri.path))
  logger.info "Downloading image from URL: #{image_url} to #{filename}"
  File.open(filename, 'wb') do |file|
    file.write(Net::HTTP.get(uri))
  end
  filename
end

def apply_text_with_imagemagick(phrase, input_image_path)
  image = MiniMagick::Image.open(input_image_path)
  image.combine_options do |c|
    c.gravity 'Center'
    c.font 'DejaVu-Sans'  # Specify DejaVu Sans font
    c.draw "text 0,0 '#{phrase}'"
    c.fill 'black'
    c.pointsize '50'
  end
  output_image_path = File.join(Dir.tmpdir, "output_#{File.basename(input_image_path)}")
  image.write(output_image_path)
  logger.info "Image written to: #{output_image_path}"
  output_image_path
end

def apply_text_with_library(input_image_path, phrase)
  image = MiniMagick::Image.open(input_image_path)
  image.combine_options do |c|
    c.gravity 'Center'
    c.font 'DejaVu-Sans'  # Specify DejaVu Sans font
    c.draw "text 0,0 '#{phrase}'"
    c.fill 'black'
    c.pointsize '50'
  end
  logger.info "Image processed with library"
  image.to_blob
end

class FeatureFlags
  def use_library?
    # Implement your feature flag logic here
    true
  end
end
