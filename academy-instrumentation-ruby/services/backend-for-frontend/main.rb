require 'sinatra'
require 'dotenv/load'
# require 'aws-sdk-s3'
require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'

# Set up OpenTelemetry
OpenTelemetry::SDK.configure do |c|
  c.service_name = 'backend-for-frontend'
  c.use_all() # enables all instrumentation!
  c.add_span_processor(OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
    OpenTelemetry::Exporter::OTLP::Exporter.new(endpoint: ENV['OTEL_EXPORTER_OTLP_ENDPOINT'])
  ))
end

# AWS S3 Client
# s3 = Aws::S3::Client.new

get '/' do
  'Hello from Backend for Frontend!'
end

get '/generate' do
  # Generate meme logic
end

# Additional routes and logic
