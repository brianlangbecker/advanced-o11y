# SPDX-License-Identifier: Apache-2.0

require 'bundler/setup'
Bundler.require
require 'async/await'
require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'
require 'opentelemetry/instrumentation/all'

OpenTelemetry::SDK.configure do |c|
  c.service_name = 'year-ruby'
  # Enable all auto-instrumentation available
  c.use_all
end

Tracer = OpenTelemetry.tracer_provider.tracer('year-internal')

class Work
  include Async::Await

  def get_random_int(max)
    rand(1..max)
  end

  def add_recursive_span(depth, max_depth)
    Tracer.in_span(
      'generated-span',
      attributes: { "depth": depth }
    ) do |_span|
      sleep(get_random_int(250) / 1000.0)

      add_recursive_span(depth + 1, max_depth) if depth < max_depth
    end
  end

  def generate_linked_trace
    # get current span
    source_span = OpenTelemetry::Trace.current_span
    link = OpenTelemetry::Trace::Link.new(source_span.context)
    # add link to new span with context from current span
    Tracer.in_span('ruby_generated-span', links: [link]) do |_span|
      sleep(get_random_int(250) / 1000.0)
      add_recursive_span(2, 5)
    end
  end

  async def do_some_work(parent_context)
    OpenTelemetry::Context.with_current(parent_context) do
      Tracer.in_span('📆 play with async') do |span|
        sleep rand(0..3)

        # Let's show how to add span events to main event
        mutex = Mutex.new
        span.add_event('Acquiring lock')
        if mutex.try_lock
          span.add_event('Got lock, doing work...')
          sleep rand(0..3)
          span.add_event('Releasing lock')
        else
          span.add_event('Lock already in use')
        end

        generate_linked_trace
      end
    end
  end
end

class App < Grape::API
  format :txt
  get :year do
    Tracer.in_span('📆 get-a-year ✨') do |span|
      work = Work.new

      # Must pass in the context to the new thread
      work.do_some_work(OpenTelemetry::Context.current)

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
