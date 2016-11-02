module Saiyan
  alias AllParamTypes = Nil | String | Int64 | Float64 | Bool | Hash(String, JSON::Type) | Array(JSON::Type)
  alias JsonHash = Hash(String, AllParamTypes)

  class JsonConverter
    @json : JsonHash
    @result : Hash(String, JSON::Any)

    def initialize(@json)
      @result = Hash(String, JSON::Any).new
    end

    getter json, result

    def to_json_api
      json.each do |key, value|
        return convert(key, value.as(Hash))
      end
    end

    private def convert(name, object)
      result.merge!(object_metadata(name + 's', object["id"]))
      attributes = Hash(String, JSON::Any).new

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
        "id" => JSON::Any.new(id),
        "type" => JSON::Any.new(type_name)
      }
    end

    private def insert_attribute(hash, key, value)
      return if ["id", "type"].includes?(key)
      hash[key.as(String)] = JSON.parse(value.to_json)
    end

    private def process_relationship_metadata(relationships)
      metadata = Hash(String, JSON::Any).new

      relationships.as(Hash).each do |key, value|
        keystr = key.as(String)
        attributes = Hash(String, JSON::Any).new

        if value.is_a?(Hash)
          object = object_metadata(keystr + 's', value.as(Hash)["id"])
          insert_attribute(attributes, "data", object)
        else
          objects = [] of Hash(String, JSON::Any)
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
      data = [] of Hash(String, JSON::Any)

      relationships.as(Hash).each do |key, value|
        keystr = key.as(String)
        attributes = Hash(String, JSON::Any).new

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
      attributes = Hash(String, JSON::Any).new

      object.each do |key, value|
        insert_attribute(attributes, key, value)
      end

      insert_attribute(data, "attributes", attributes)
      data
    end
  end
end
