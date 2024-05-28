require 'net/http'
require 'json'
require 'logger'

# Initialize the logger
logger = Logger.new(STDOUT)
logger.level = Logger::INFO

SERVICES = {
  'meminator' => 'http://meminator:10114/applyPhraseToPicture',
  'phrase-picker' => 'http://phrase-picker:10114/phrase',
  'image-picker' => 'http://image-picker:10114/imageUrl'
}

def fetch_from_service(service, options = {})
  uri = URI(SERVICES[service])
  http = Net::HTTP.new(uri.host, uri.port)
  request = case options[:method]
            when 'POST'
              req = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
              req.body = options[:body].to_json if options[:body]
              req['Content-Length'] = req.body.bytesize.to_s if req.body
              req
            else
              Net::HTTP::Get.new(uri.path, 'Content-Type' => 'application/json')
            end

  begin
    logger.info "Sending request to #{service} with headers: #{request.to_hash} and body: #{request.body}"
    response = http.request(request)
    logger.info "Fetch from service (#{service}): #{response.code} #{response.message}, Headers: #{response.to_hash}"
    response
  rescue StandardError => e
    logger.error "Error fetching from service (#{service}): #{e.message}"
    raise
  end
end
