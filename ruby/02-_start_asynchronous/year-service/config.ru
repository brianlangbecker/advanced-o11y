# SPDX-License-Identifier: Apache-2.0

require "bundler/setup"
Bundler.require
require 'async/await'
require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'
require 'opentelemetry/instrumentation/all'

OpenTelemetry::SDK.configure do |c|
  c.service_name = "year-ruby"
  # Enable all auto-instrumentation available
  c.use_all()
end

Tracer = OpenTelemetry.tracer_provider.tracer("year-internal")

class Work
  include Async::Await
  async def doSomeWork(parent_context)
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
    # Starting a span in context of trace
    Tracer.in_span("📆 get-a-year ✨") do |span|

      while 
      work = Work.new
      # Must pass in the context to the new thread for async
      # to properly trace
      work.doAsync(OpenTelemetry::Context.current)
		
      sleep rand(0..3)
      year = (2015..2020).to_a.sample
      
      # Adding a span event
      span.set_attribute("random.year", year)
      year
    end
  end
end

use OpenTelemetry::Instrumentation::Rack::Middlewares::TracerMiddleware
run App