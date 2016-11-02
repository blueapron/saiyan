require "./saiyan/*"
require "kemal"
require "json"
require "logger"

log = Logger.new(STDOUT)
log.level = Logger::DEBUG

get "/" do
  "Hello World!"
end

post "/convert" do |env|
  env.response.content_type = "application/vnd.api+json"

  # log.debug(env.params.json)
  results = convert_to_json_api(env.params.json)

  # env.params.json.each do |key, value|
  #   results[value.to_s] = key
  # end
  results["test"] = "blah"
  results.to_json
end

def convert_to_json_api(json)
  return json if json.empty?
  results = Hash(String, JSON::Type).new
end

Kemal.run
