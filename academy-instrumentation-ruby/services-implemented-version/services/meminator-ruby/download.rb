require 'sinatra'
require 'json'
require 'net/http'
require 'uri'
require 'open-uri'
require 'mini_magick'
require './feature_flags'
require './apply_text_with_imagemagick'
require './apply_text_with_library'
require 'fileutils'

set :port, 10114

# Health check endpoint
get '/health' do
  'OK'
end

post '/applyPhraseToPicture' do
  content_type :json
  request.body.rewind
  input = JSON.parse(request.body.read)
  input_phrase = input['phrase']
  image_url = input['imageUrl']

  phrase = input_phrase.upcase

  begin
    # download the image, defaulting to a local image
    input_image_path = download(image_url)

    if FeatureFlags.new.use_library?
      output_buffer = apply_text_with_library(input_image_path, phrase)
      content_type 'image/png'
      return output_buffer
    else
      output_image_path = apply_text_with_imagemagick(phrase, input_image_path)
      send_file output_image_path, type: 'image/png'
    end

  rescue => e
    status 500
    body 'Internal Server Error'
    STDERR.puts "Error creating picture: #{e.message}"
  end
end

def download(image_url)
  uri = URI.parse(image_url)
  filename = File.join(Dir.tmpdir, File.basename(uri.path))
  File.open(filename, 'wb') do |file|
    file.write(Net::HTTP.get(uri))
  end
  filename
end

def apply_text_with_imagemagick(phrase, input_image_path)
  image = MiniMagick::Image.open(input_image_path)
  image.combine_options do |c|
    c.gravity 'Center'
    c.draw "text 0,0 '#{phrase}'"
    c.fill 'white'
    c.pointsize '50'
  end
  output_image_path = File.join(Dir.tmpdir, "output_#{File.basename(input_image_path)}")
  image.write(output_image_path)
  output_image_path
end

def apply_text_with_library(input_image_path, phrase)
  image = MiniMagick::Image.open(input_image_path)
  image.combine_options do |c|
    c.gravity 'Center'
    c.draw "text 0,0 '#{phrase}'"
    c.fill 'white'
    c.pointsize '50'
  end
  image.to_blob
end

class FeatureFlags
  def use_library?
    # Implement your feature flag logic here
    true
  end
end
