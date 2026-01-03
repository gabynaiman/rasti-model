module Rasti
  class Model
    module Schema
      class << self

        def register_type_serializer(type, serialized_type=nil, &block)
          type_serializers[type] = block || serialized_type
        end

        def serialize(model_class)
          attributes = model_class.attributes.map do |attribute|
            serialize_attribute(attribute).merge(name: attribute.name)
          end

          {
            model: model_class.name || model_class.to_s,
            attributes: attributes
          }
        end

        private

        def type_serializers
          @type_serializers ||= {}
        end

        def serialize_attribute(attribute)
          serialization = serialize_type(attribute.type)
          
          options = attribute.send(:options)
          serialization[:options] = options unless options.empty?
          
          serialization
        end

        def serialize_type(type)
          if type.nil?
            return {type: :any}
          end

          if (serializer = type_serializers[type])
            return serializer.is_a?(Proc) ? serializer.call(type) : {type: serializer}
          end

          if type.respond_to? :to_schema
            return type.to_schema
          end

          if type.is_a?(Class)
            if type <= Types::String
              {type: :string}
            elsif type <= Types::Integer
              {type: :integer}
            elsif type <= Types::Float
              {type: :float}
            elsif type <= Types::Boolean
              {type: :boolean}
            elsif type <= Types::Symbol
              {type: :symbol}
            elsif type <= Types::Regexp
              {type: :regexp}
            else
              {type: :unknown, details: type.name || type.to_s}
            end
          elsif type.is_a?(Types::Time)
            {type: :time, format: type.format}
          elsif type.respond_to?(:values)
            {type: :enum, values: type.values}
          elsif type.is_a?(Types::Array)
            {type: :array, items: serialize_type(type.type)}
          elsif type.is_a?(Types::Hash)
            {type: :hash, key_type: serialize_type(type.key_type), value_type: serialize_type(type.value_type)}
          elsif type.is_a?(Types::Model)
            {type: :model, model: type.model.name || type.model.to_s, schema: serialize(type.model)}
          else
            {type: :unknown, details: type.to_s}
          end
        end

      end
    end
  end
end