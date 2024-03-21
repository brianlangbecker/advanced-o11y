require "bundler/setup"
Bundler.require

require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'
require 'opentelemetry/instrumentation/all'
require 'async/await'

begin
  OpenTelemetry::SDK.configure do |c|
    c.service_name = "year-ruby"

    # Enable all auto-instrumentation available
    c.use_all()
  end
rescue OpenTelemetry::SDK::ConfigurationError => e
  puts "What now?"
  puts e.inspect
end

Tracer = OpenTelemetry.tracer_provider.tracer("year-internal")

class App < Grape::API
  format :txt

  get :year do
    # Starting a span in context of trace
    Tracer.in_span("🗓 get-a-year ✨") do
      sleep rand(0..0.005)
      year = (2015..2020).to_a.sample
      
      # Adding a span event
      current_span = OpenTelemetry::Trace.current_span
      current_span.set_attribute("random.year", year)
      year
    end
  end

end

use OpenTelemetry::Instrumentation::Rack::Middlewares::TracerMiddleware
run App