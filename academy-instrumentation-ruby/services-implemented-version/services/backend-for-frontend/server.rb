require "bundler/setup"
Bundler.require

require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'
require 'opentelemetry/instrumentation/all'
require 'sinatra'
require 'net/http'
require 'json'

require_relative 'o11yday_lib'  # Ensure this is the correct path to your helper file

configure do
  set :port, 10114
end

begin
  OpenTelemetry::SDK.configure do |c|
    c.service_name = ENV['SERVICE_NAME'] || "backend-for-frontend-ruby"
    c.use_all
  end
rescue StandardError => e
  puts "OpenTelemetry configuration failed: #{e.message}"
end

get '/health' do
  content_type :json
  { message: "I am here at frontend-for-backend", status_code: 0 }.to_json
end

post '/createPicture' do
  begin
    current_span = OpenTelemetry::Trace.current_span
    phrase_response = fetch_from_service('phrase-picker')
    image_response = fetch_from_service('image-picker')

    phrase_text = phrase_response.is_a?(Net::HTTPSuccess) ? phrase_response.body : "{}"
    image_text = image_response.is_a?(Net::HTTPSuccess) ? image_response.body : "{}"
    current_span.set_attribute("app.phrase", phrase_text);
    current_span.set_attribute("app.image_url", image_text);

    phrase_result = JSON.parse(phrase_text)
    image_result = JSON.parse(image_text)

    merged_body = phrase_result.merge(image_result)

    response = fetch_from_service('meminator', method: 'POST', body: merged_body)

    halt 500, 'Internal Server Error' unless response.is_a?(Net::HTTPSuccess)

    content_type 'image/png'
    response_body = response.body
    response_body.force_encoding('BINARY') if response_body.respond_to?(:force_encoding)
    stream do |out|
      out << response_body
    end
  rescue JSON::ParserError => e
    halt 500, 'Internal Server Error'
  rescue StandardError => e
    halt 500, 'Internal Server Error'
  end
end

use OpenTelemetry::Instrumentation::Rack::Middlewares::TracerMiddleware
