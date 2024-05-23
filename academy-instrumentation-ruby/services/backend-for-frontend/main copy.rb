require 'sinatra'
require 'net/http'
require 'json'
require 'uri'

helpers do
  def fetch_from_service(service_name, options = {})
    uri = URI("http://localhost:#{service_port(service_name)}/")
    http = Net::HTTP.new(uri.host, uri.port)
    request = case options[:method]
              when 'POST'
                req = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
                req.body = options[:body].to_json
                req
              else
                Net::HTTP::Get.new(uri.path)
              end
    http.request(request)
  end

  def service_port(service_name)
    case service_name
    when 'phrase-picker' then 10115
    when 'image-picker' then 10116
    when 'meminator' then 10117
    else raise "Unknown service: #{service_name}"
    end
  end
end

set :port, 10114

get '/health' do
  content_type :json
  { message: 'I am here', status_code: 0 }.to_json
end

post '/createPicture' do
  content_type 'image/png'
  begin
    phrase_response = fetch_from_service('phrase-picker')
    image_response = fetch_from_service('image-picker')

    phrase_text = phrase_response.is_a?(Net::HTTPSuccess) ? phrase_response.body : '{}'
    image_text = image_response.is_a?(Net::HTTPSuccess) ? image_response.body : '{}'

    phrase_result = JSON.parse(phrase_text)
    image_result = JSON.parse(image_text)

    meminator_response = fetch_from_service('meminator', method: 'POST', body: phrase_result.merge(image_result))

    if !meminator_response.is_a?(Net::HTTPSuccess) || meminator_response.body.nil?
      raise "Failed to fetch picture from meminator: #{meminator_response.code} #{meminator_response.message}"
    end

    stream do |out|
      out.write meminator_response.body
    end
  rescue => e
    puts "Error creating picture: #{e}"
    status 500
    'Internal Server Error'
  end
end

# Start the server
run Sinatra::Application.run!
