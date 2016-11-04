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
      result.merge!(object_metadata(name + 's', object["id"]))
      attributes = Hash(String, JsonObject).new

      relationships = Hash(String, JSON::Type | Array(JSON::Type)).new

      object.each do |key, value|
        if value.is_a?(Hash) || value.is_a?(Array)
          relationships[key] = value
        else
           insert_attribute(attributes, key, value)
        end
      end

      insert_attribute(result, "attributes", attributes)
      process_relationship_metadata(relationships)
      process_relationships(relationships)

      result
    end

    private def object_metadata(type_name, id)
      {
        "id" => JsonObject.new(id),
        "type" => JsonObject.new(type_name)
      }
    end

    private def insert_attribute(hash, key, value)
      return if ["id", "type"].includes?(key)
      hash[key.as(String)] = JsonObject.new(value)
    end

    private def process_relationship_metadata(relationships)
      metadata = Hash(String, JsonObject).new

      relationships.each do |key, value|
        keystr = key.as(String)
        attributes = Hash(String, JsonObject).new

        if value.is_a?(Hash)
          object = object_metadata(keystr + 's', value.as(Hash)["id"])
          insert_attribute(attributes, "data", object)
        else
          objects = [] of Hash(String, JsonObject)
          value.as(Array).each do |obj|
            objects << object_metadata(keystr, obj.as(Hash)["id"])
          end
          insert_attribute(attributes, "data", objects)
        end

        insert_attribute(metadata, key, attributes)
      end

      insert_attribute(result, "relationships", metadata)
    end

    private def process_relationships(relationships)
      data = [] of Hash(String, JsonObject)

      relationships.each do |key, value|
        keystr = key.as(String)
        attributes = Hash(String, JsonObject).new

        if value.is_a?(Hash)
          data << process(keystr + 's', value.as(Hash))
        else
          value.as(Array).each do |obj|
            data << process(keystr, obj.as(Hash))
          end
        end
      end

      insert_attribute(result, "included", data)
    end

    private def process(name, object)
      data = object_metadata(name, object["id"])
      attributes = Hash(String, JsonObject).new

      object.each do |key, value|
        insert_attribute(attributes, key, value)
      end

      insert_attribute(data, "attributes", attributes)
      data
    end
  end
end
