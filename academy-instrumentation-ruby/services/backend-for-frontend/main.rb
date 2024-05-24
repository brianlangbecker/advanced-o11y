require 'sinatra'
require 'net/http'
require 'json'
require_relative 'o11yday_lib'  # Ensure this is the correct path to your helper file

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

get '/health' do
  content_type :json
  { message: "I am here at frontend-for-backend", status_code: 0 }.to_json
end

post '/createPicture' do
  begin
    logger.info "Fetching phrase..."
    phrase_response = fetch_from_service('phrase-picker')
    logger.info "Phrase response: #{phrase_response.code} #{phrase_response.message}"

    logger.info "Fetching image..."
    image_response = fetch_from_service('image-picker')
    logger.info "Image response: #{image_response.code} #{image_response.message}"

    phrase_text = phrase_response.is_a?(Net::HTTPSuccess) ? phrase_response.body : "{}"
    image_text = image_response.is_a?(Net::HTTPSuccess) ? image_response.body : "{}"

    logger.info "Phrase text: #{phrase_text}"
    logger.info "Image text: #{image_text}"

    phrase_result = JSON.parse(phrase_text)
    image_result = JSON.parse(image_text)

    logger.info "Merging phrase and image results..."
    merged_body = phrase_result.merge(image_result)
    logger.info "Merged body: #{merged_body}"

    logger.info "Fetching meminator..."
    response = fetch_from_service('meminator', method: 'POST', body: merged_body)
    logger.info "Meminator response: #{response.code} #{response.message}"

    halt 500, 'Internal Server Error' unless response.is_a?(Net::HTTPSuccess)

    content_type 'image/png'
    response_body = response.body
    response_body.force_encoding('BINARY') if response_body.respond_to?(:force_encoding)
    stream do |out|
      out << response_body
    end
  rescue JSON::ParserError => e
    logger.error "JSON Parsing Error: #{e.message}"
    halt 500, 'Internal Server Error'
  rescue StandardError => e
    logger.error "Error creating picture: #{e.message}"
    halt 500, 'Internal Server Error'
  end
end

post '/createPicture2' do
  begin
    data = request.body.read
    logger.info "Received data: #{data}"
    parsed_data = JSON.parse(data)
    logger.info "Parsed data: #{parsed_data}"

    content_type :json
    { status: "success", received_data: parsed_data }.to_json
  rescue JSON::ParserError => e
    logger.error "JSON Parsing Error: #{e.message}"
    halt 400, 'Invalid JSON'
  rescue StandardError => e
    logger.error "Error processing request: #{e.message}"
    halt 500, 'Internal Server Error'
  end
end
