module Saiyan
  alias AllParamTypes = Nil | String | Int64 | Float64 | Bool | Hash(String, JSON::Type) | Array(JSON::Type)
  alias JsonHash = Hash(String, AllParamTypes)
  alias TerminalTypes = Nil | String | Int64 | Float64 | Bool | Array(JSON::Type) | JSON::Type

  class JsonObject
    @raw : Nil | String | Int64 | Float64 | Bool | Array(JSON::Type) | JSON::Type | Hash(String, TerminalTypes) | Hash(String, JsonObject) |  Array(Hash(String, JsonObject))

    def initialize(@raw)
    end

    def to_s
      @raw.to_s
    end

    def to_json(io)
      @raw.to_json(io)
    end
  end

  class JsonConverter
    @json : JsonHash
    @result : Hash(String, JsonObject)

    def initialize(@json)
      @result = Hash(String, JsonObject).new
    end

    getter json, result

    def to_json_api
      json.each do |key, value|
        return convert(key, value.as(Hash))
      end
    end

    private def convert(name, object)
      result.merge!(object_identifier(name + 's', object["id"]))

      attributes = Hash(String, JsonObject).new
      relationships = Hash(String, JSON::Type | Array(JSON::Type)).new

      object.each do |key, value|
        if value.is_a?(Hash) || value.is_a?(Array)
          relationships[key] = value
        else
          insert_json(attributes, key, value)
        end
      end

      insert_json(result, "attributes", attributes)
      parse_relationships(relationships)

      result
    end

    private def object_identifier(type_name, id)
      {
        "id" => JsonObject.new(id),
        "type" => JsonObject.new(type_name)
      }
    end

    private def insert_json(hash, key, value)
      return if ["id", "type"].includes?(key)
      hash[key.as(String)] = JsonObject.new(value)
    end

    private def parse_relationships(relationships)
      metadata = Hash(String, JsonObject).new
      data = [] of Hash(String, JsonObject)

      relationships.each do |key, value|
        key = key.as(String)

        if value.is_a?(Hash)
          identifier = object_identifier(key + 's', value.as(Hash)["id"])
          data << parse(key + 's', value.as(Hash))
        else
          identifier = [] of Hash(String, JsonObject)
          value.as(Array).each do |obj|
            identifier << object_identifier(key, obj.as(Hash)["id"])
            data << parse(key, obj.as(Hash))
          end
        end

        insert_json(metadata, key, { "data" => JsonObject.new(identifier) })
      end

      insert_json(result, "relationships", metadata)
      insert_json(result, "included", data)
    end

    private def parse(name, object)
      data = object_identifier(name, object["id"])
      attributes = Hash(String, JsonObject).new

      object.each do |key, value|
        insert_json(attributes, key, value)
      end

      insert_json(data, "attributes", attributes)
      data
    end
  end
end
