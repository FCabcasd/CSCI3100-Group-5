module ApiHelpers
  include Rack::Test::Methods

  def app
    Rails.application
  end

  def json_post(path, params: {}, headers: {})
    headers.each { |k, v| header k, v }
    header 'Content-Type', 'application/json'
    post path, params.to_json
  end

  def json_get(path, headers: {})
    headers.each { |k, v| header k, v }
    get path
  end

  def json_delete(path, headers: {})
    headers.each { |k, v| header k, v }
    delete path
  end

  def response
    last_response
  end

  def response_json
    JSON.parse(last_response.body)
  end
end

World(ApiHelpers)
