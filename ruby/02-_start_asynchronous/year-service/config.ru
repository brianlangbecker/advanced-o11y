require "bundler/setup"
Bundler.require
require 'async/await'
require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'
require 'opentelemetry/instrumentation/all'

OpenTelemetry::SDK.configure do |c|
  c.service_name = "year-ruby"
  # enable all auto-instrumentation available
  c.use_all()
end

Tracer = OpenTelemetry.tracer_provider.tracer("year-internal")

class DoWork
  include Async::Await
  async def doAsync(parent_context)
    OpenTelemetry::Context.with_current(parent_context) do
      Tracer.in_span("📆 play with async") do |span|
        sleep rand(0..3)
        puts "💩"
		    span.add_event("💩")
      end
    end
  end
end

class App < Grape::API
  format :txt
  get :year do
    Tracer.in_span("📆 get-a-year ✨") do |span|
      work = DoWork.new
      work.doAsync(OpenTelemetry::Context.current)
		
      sleep rand(0..3)
      year = (2015..2020).to_a.sample
      year
      # a span event!
      span.set_attribute("random.year", year)
      year
    end
  end
end

use OpenTelemetry::Instrumentation::Rack::Middlewares::TracerMiddleware
run App