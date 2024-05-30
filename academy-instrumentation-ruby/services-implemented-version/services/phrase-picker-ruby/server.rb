require "bundler/setup"
Bundler.require

require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'
require 'opentelemetry/instrumentation/all'
require 'sinatra'
require 'json'
require 'securerandom'

# Configure OpenTelemetry
  begin
    OpenTelemetry::SDK.configure do |c|
      c.service_name = ENV['SERVICE_NAME'] || "phrase-picker-ruby"
      c.use_all
    end
  rescue StandardError => e
    puts "OpenTelemetry configuration failed: #{e.message}"
  end

PHRASES = [
  'you\'re muted',
  'not dead yet',
  'Let them.',
  'Boiling Loves Company!',
  'Must we?',
  'SRE not-sorry',
  'Honeycomb at home',
  'There is no cloud',
  'This is fine',
  'It\'s a trap!',
  'Not Today',
  'You had one job',
  'bruh',
  'have you tried restarting?',
  'try again after coffee',
  'deploy != release',
  'oh, just the crimes',
  'not a bug, it\'s a feature',
  'test in prod',
  'who broke the build?'
]

# Route for health check
get '/health' do
  content_type :json
  { message: 'I am here, ready to pick a phrase', status_code: 0 }.to_json
end

# Route for getting a random phrase
get '/phrase' do
  content_type :json
  { phrase: PHRASES.sample }.to_json
end

# Start the server
set :port, 10114
set :bind, '0.0.0.0'

use OpenTelemetry::Instrumentation::Rack::Middlewares::TracerMiddleware
