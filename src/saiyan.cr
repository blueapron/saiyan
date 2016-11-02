require "./saiyan/*"
require "kemal"
require "json"

get "/" do
  "Hello World!"
end

post "/convert" do |env|
  env.response.content_type = "application/vnd.api+json"

  if env.request.body.nil?
    raise Exception.new("Need something to convert!")
  end

  json = env.params.json

  if json.keys.size > 1
    raise Exception.new("Can only handle one object!")
  end

  serializer = Saiyan::JsonConverter.new(json)
  { "data": serializer.to_json_api }.to_json
end

def convert_to_json_api(json)
  return json if json.empty?
  results = Hash(String, Hash(String, JSON::Type)).new
end

Kemal.run
