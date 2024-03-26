# SPDX-License-Identifier: Apache-2.0

require 'async'
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
  def self.do_some_work(span)
    new.do_some_work(span)
  end

  def do_some_work(parent_span)
    n = 4
    span_context = parent_span.context
    parent_end = (Time.now + rand(0.1..0.2)).to_f
    Async do
      n.times do |i|
        Async do
          span = OpenTelemetry::Trace.non_recording_span(span_context)
          OpenTelemetry::Trace.with_span(span) do
            Tracer.in_span('Some Async Work ✨ ' + i.to_s) do |span|
              sleep_randomly(1000)
            end
          end
        end
      end
    end
    parent_span.finish(end_timestamp: parent_end)
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
    current_year = Time.now.year
    span = Tracer.start_span('📆 get-a-year ✨')
    year = (2015..current_year).to_a.sample
    span.set_attribute('random.year', year)
    Worker.do_some_work(span)
    year
  end
end

use OpenTelemetry::Instrumentation::Rack::Middlewares::TracerMiddleware
run App
