# SPDX-License-Identifier: Apache-2.0

require 'bundler/setup'
Bundler.require
require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'
require 'opentelemetry/instrumentation/all'

begin
  OpenTelemetry::SDK.configure do |c|
    c.service_name = 'year-ruby'
    # Enable all auto-instrumentation available
    c.use_all
  end
rescue OpenTelemetry::SDK::ConfigurationError => e
  puts 'What now?'
  puts e.inspect
end

Tracer = OpenTelemetry.tracer_provider.tracer('year-internal')

class Worker
  def self.do_some_work
    new.do_some_work
  end

  def do_some_work
    Tracer.in_span('📆 play with async') do |_span|
      sleep_randomly(3000)
      # Running this method in a separate thread will disconnect it from
      # the current span, so pass in the span's context
      Thread.new { generate_async(OpenTelemetry::Context.current) }.join
    end
  end

  # When run in a separate thread, spans started in this method will appear
  # on a separate trace, you ensure they use the parent_context so they stay in the same trace
  def generate_async(parent_context)
    OpenTelemetry::Context.with_current(parent_context) do
      sleep_randomly(250)
    end
  end

  def sleep_randomly(max)
    sleep(get_random_int(max) / 1000.0)
  end

  def get_random_int(max)
    rand(1..max).tap { |i| OpenTelemetry::Trace.current_span.set_attribute('app.worker.sleep.random_int', i) }
  end
end

class App < Grape::API
  format :txt
  get :year do
    Tracer.in_span('📆 get-a-year ✨') do |span|
      Worker.do_some_work

      sleep rand(0..3)
      year = (2015..2020).to_a.sample
      # a span event!
      span.set_attribute('random.year', year)
      year
    end
  end
end

use OpenTelemetry::Instrumentation::Rack::Middlewares::TracerMiddleware
run App
