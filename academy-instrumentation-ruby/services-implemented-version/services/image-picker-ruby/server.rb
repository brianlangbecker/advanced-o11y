require 'sinatra'
require 'json'
require 'securerandom'
require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'

set :port, 10114
set :bind, '0.0.0.0'

FILENAMES = [
  'Angrybird.JPG',
  'Arco&Tub.png',
  'IMG_9343.jpg',
  'heatmap.png',
  'angry-lemon-ufo.JPG',
  'austintiara4.png',
  'baby-geese.jpg',
  'bbq.jpg',
  'beach.JPG',
  'bunny-mask.jpg',
  'busted-light.jpg',
  'cat-glowing-eyes.JPG',
  'cat-on-leash.JPG',
  'cat-with-bowtie.heic',
  'cat.jpg',
  'clementine.png',
  'cow-peeking.jpg',
  'different-animals-01.png',
  'dratini.png',
  'everything-is-an-experiment.png',
  'experiment.png',
  'fine-food.jpg',
  'flower.jpg',
  'frenwho.png',
  'genshin-spa.jpg',
  'grass-and-desert-guy.png',
  'honeycomb-dogfood-logo.png',
  'horse-maybe.png',
  'is-this-emeri.png',
  'jean-and-statue.png',
  'jessitron.png',
  'keys-drying.jpg',
  'lime-on-soap-dispenser.jpg',
  'loki-closeup.jpg',
  'lynia.png',
  'ninguang-at-work.png',
  'paul-r-allen.png',
  'please.png',
  'roswell-nose.jpg',
  'roswell.JPG',
  'salt-packets-in-jar.jpg',
  'scarred-character.png',
  'square-leaf-with-nuts.jpg',
  'stu.jpeg',
  'sweating-it.png',
  'tanuki.png',
  'tennessee-sunset.JPG',
  'this-is-fine-trash.jpg',
  'three-pillars-2.png',
  'trash-flat.jpg',
  'walrus-painting.jpg',
  'windigo.png',
  'yellow-lines.JPG'
]

begin
  OpenTelemetry::SDK.configure do |c|
    c.service_name = ENV['SERVICE_NAME'] || "image-service"

    # enable all auto-instrumentation available
    c.use_all()

    # add the Baggage and CarryOn processors to the pipeline
    c.add_span_processor(O11yWrapper::BaggageSpanProcessor.new)
    c.add_span_processor(O11yWrapper::CarryOnSpanProcessor.new)

    # Because we tinkered with the pipeline, we'll need to
    # wire up span batching and sending via OTLP ourselves.
    # This is usually the default.
    c.add_span_processor(
      OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
        OpenTelemetry::Exporter::OTLP::Exporter.new()
      )
    )
  end
rescue StandardError => e
  puts "OpenTelemetry configuration failed: #{e.message}"
end

BUCKET_NAME = ENV['BUCKET_NAME'] || 'random-pictures'
IMAGE_URLS = FILENAMES.map { |filename| "https://#{BUCKET_NAME}.s3.amazonaws.com/#{filename}" }

get '/health' do
  content_type :json
  { message: 'I am here, ready to pick an image', status_code: 0 }.to_json
end

get '/imageUrl' do
  tracer = OpenTelemetry.tracer_provider.tracer('image-service')
  span = tracer.start_span('get_image_url')

  begin
    content_type :json
    image_url = IMAGE_URLS.sample

    span.set_attribute('image.url', image_url)
    span.set_attribute('image.bucket', BUCKET_NAME)
    span.set_attribute('image.filenames_count', FILENAMES.size)

    response = { imageUrl: image_url }.to_json
  rescue StandardError => e
    span.record_exception(e)
    span.status = OpenTelemetry::Trace::Status.new(OpenTelemetry::Trace::Status::ERROR, description: e.message)
    response = { error: 'Failed to fetch image URL' }.to_json
  ensure
    span.finish
  end

  response
end

helpers do
  def choose(array)
    array.sample
  end
end
