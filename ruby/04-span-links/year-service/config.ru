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
    Tracer.in_span('📆 play with async') do |span|
      sleep_randomly(3000)

      # Let's show how to add span events to main event
      mutex = Mutex.new
      span.add_event('Acquiring lock')
      if mutex.try_lock
        span.add_event('Got lock, doing work...')

        # Running this method in a separate thread will disconnect it from
        # the current span, so pass in the span's context so that a link can be
        # made back to it.
        Thread.new { generate_linked_trace(span.context) }.join

        span.add_event('Releasing lock')
        mutex.unlock
      else
        span.add_event('Lock already in use, skipping work')
      end
    end
  end

  # When run in a separate thread, spans started in this method will appear
  # on a separate trace. Pass the context of the span that runs this method
  # in as a parameter to link the two traces.
  def generate_linked_trace(linked_context)
    # link this span to the span that spawned it
    link_to_spawning_span = OpenTelemetry::Trace::Link.new(linked_context)
    Tracer.in_span('ruby-generated-span', links: [link_to_spawning_span]) do
      sleep_randomly(250)
      add_recursive_span(2, 5)
    end
  end

  def add_recursive_span(depth, max_depth)
    Tracer.in_span('generated-span', attributes: { 'depth' => depth }) do
      sleep_randomly(250)
      add_recursive_span(depth + 1, max_depth) if depth < max_depth
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
