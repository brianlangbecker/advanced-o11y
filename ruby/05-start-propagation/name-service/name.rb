require 'sinatra'
require 'honeycomb-beeline'
require 'honeycomb/propagation/w3c'
require 'faraday'

Honeycomb.configure do |config|
  config.write_key = ENV['HONEYCOMB_API_KEY']
  config.service_name = ENV['SERVICE_NAME'] || 'name-ruby'
  config.dataset = ENV['SERVICE_NAME'] || 'name-ruby'
  # config.api_host = ENV['HONEYCOMB_API_ENDPOINT']
  # missing something to ensure it reports
  # config.client = Libhoney::LogClient.new
  # config.debug = true
  config.http_trace_propagation_hook do |env, context|
    Honeycomb::W3CPropagation::MarshalTraceContext.parse_faraday_env env, context
  end
end

use Honeycomb::Sinatra::Middleware, client: Honeycomb.client

set :bind, '0.0.0.0'
set :port, 8000

names_by_year = {
  2015 => %w[sophia jackson emma aiden olivia liam ava lucas mia noah],
  2016 => %w[sophia jackson emma aiden olivia lucas ava liam mia noah],
  2017 => %w[sophia jackson olivia liam emma noah ava aiden isabella lucas],
  2018 => %w[sophia jackson olivia liam emma noah ava aiden isabella caden],
  2019 => %w[sophia liam olivia jackson emma noah ava aiden aira grayson],
  2020 => %w[olivia noah emma liam ava elijah isabella oliver sophia lucas],
  2021 => %w[olivia isabella oliver noah emma liam ava elijah sophia lucas],
  2022 => %w[olivia liam ava elijah isabella oliver sophia lucas noah emma],
  2023 => %w[olivia elijah isabella noah emma liam ava oliver sophia lucas],
  2024 => %w[oliver olivia noah emma liam ava elijah isabella oliver sophia lucas]
}

get '/name' do
  Honeycomb.start_span(name: 'name') do
    year = get_year
    names = names_by_year[year]
    name = names[rand(names.length)]
    Honeycomb.add_field('name', name)
    Honeycomb.add_field('year', year)
    name + " " + year.to_s
  end
end

def get_year
  year_service_connection = Faraday.new(ENV['YEAR_ENDPOINT'] || 'http://localhost:6001')
  Honeycomb.start_span(name: 'get_year') do
    year_service_response = year_service_connection.get('/year') do |request|
    end
    year_service_response.body.to_i
  end
end
