require 'sinatra'
require 'honeycomb-beeline'
require 'honeycomb/propagation/w3c'
require 'faraday'

Honeycomb.configure do |config|
  config.write_key = ENV['HONEYCOMB_API_KEY']
  config.service_name = ENV['SERVICE_NAME'] || 'name-ruby'
  config.api_host = ENV['HONEYCOMB_API_ENDPOINT']
  # missing something to ensure it reports
  config.client = Libhoney::LogClient.new
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
  2020 => %w[olivia noah emma liam ava elijah isabella oliver sophia lucas]
}

get '/name' do
  year = get_year
  names = names_by_year[year]
  names[rand(names.length)]
end

def get_year
  year_service_connection = Faraday.new(ENV['YEAR_ENDPOINT'] || 'http://localhost:6001')
  Honeycomb.start_span(name: 'honeycomb_trace') do
    year_service_response = year_service_connection.get('/year') do |request|
    end
    year_service_response.body.to_i
  end
end
