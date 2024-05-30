require "bundler/setup"
Bundler.require

require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'
require 'opentelemetry/instrumentation/all'
require 'sinatra'
require 'json'
require 'net/http'
require 'uri'
require 'open-uri'
require 'mini_magick'
require 'logger'
require 'fileutils'

# Configure OpenTelemetry
begin
  OpenTelemetry::SDK.configure do |c|
    c.service_name = ENV['SERVICE_NAME'] || "meminator-ruby"
    c.use_all
  end
rescue StandardError => e
  puts "OpenTelemetry configuration failed: #{e.message}"
end

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
  input = JSON.parse(request.body.read) rescue {"phrase" => "I got you"}
  input_phrase = input['phrase']
  image_url = input['imageUrl']
  phrase = input_phrase.upcase

  begin
    current_span = OpenTelemetry::Trace.current_span
    current_span.set_attribute("app.meminator.phrase", phrase)

    # Download the image, defaulting to a local image
    input_image_path = download(image_url)

    # Check if the file exists
    unless File.exist?(input_image_path)
      current_span.add_event(
        "image_not_found",
        attributes: {
          "input_image_path" => input_image_path,
          "imageUrl" => image_url
        }
      )
      current_span.set_status(OpenTelemetry::Trace::Status.new(OpenTelemetry::Trace::Status::ERROR))
      status 500
      return 'Downloaded image file not found'
    end

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
  begin
    image = MiniMagick::Image.open(input_image_path)
    image.combine_options do |c|
      c.gravity 'Center'
      c.font 'DejaVu-Sans'  # Specify DejaVu Sans font
      c.draw "text 0,0 '#{phrase}'"
      c.fill 'black'
      c.pointsize '150'
    end
    output_image_path = File.join(Dir.tmpdir, "output_#{File.basename(input_image_path)}")
    image.write(output_image_path)
    output_image_path
  rescue => e
    current_span = OpenTelemetry::Trace.current_span
    current_span.add_event("convert_subprocess_failed", attributes: {
      "command" => "convert -gravity Center -font DejaVu-Sans -draw 'text 0,0 #{phrase}' -fill black -pointsize 150",
      "input_image_path" => input_image_path,
      "error" => e.message
    })
    current_span.set_status(OpenTelemetry::Trace::Status.new(OpenTelemetry::Trace::Status::ERROR))
    current_span.record_exception(e)
    STDERR.puts "An error occurred: #{e.message}"
    status 500
    'An error occurred generating your image, sorry'
  end
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
  image.to_blob
end

class FeatureFlags
  def use_library?
    # Implement your feature flag logic here
    true
  end
end
