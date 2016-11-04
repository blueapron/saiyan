require "./saiyan/*"
require "kemal"
require "json"
require "http/client"

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

get "/multi" do |env|
  ch = Channel(Nil).new

  result = Hash(String, String).new

  urls = {
    "apple" => "https",
    "google" => "https",
    "blueapron" => "https",
    "nytimes" => "http"
  }

  urls.each do |domain, protocol|
    spawn do
      response = HTTP::Client.get "#{protocol}://www.#{domain}.com"
      result[domain] = response.body
      ch.send(nil)
    end
  end

  urls.size.times { ch.receive }

  result.to_json
end

Kemal.run
