require 'multi_require'
require 'rasti-types'

module Rasti
  class Model

    extend MultiRequire

    require_relative_pattern 'model/*'

    class << self

      def [](*args)
        Class.new(self) do
          if args.count == 1 && args.first.is_a?(Hash)
            args.first.each { |name, type| attribute name, type }
          else
            args.each { |name| attribute name }
          end
        end
      end

      def attributes
        @attributes ||= []
      end

      def attribute_names
        @attibute_names ||= attributes.map(&:name)
      end

      def model_name
        name || self.superclass.name
      end

      def to_s
        "#{model_name}[#{attribute_names.join(', ')}]"
      end
      alias_method :inspect, :to_s

      private

      def attribute(name, type=nil, options={})
        raise ArgumentError, "Attribute #{name} already exists" if attributes.any? { |a| a.name == name }
        attribute = Attribute.new(name, type, options)
        attributes << attribute

        define_method name do
          read_attribute attribute
        end
      end

      def inherited(subclass)
        subclass.instance_variable_set :@attributes, attributes.dup
      end

    end

    def initialize(attributes={})
      invalid_attributes = attributes.keys.map(&:to_sym) - self.class.attribute_names
      raise ArgumentError, "#{self.class.model_name} invalid attributes: #{invalid_attributes.join(', ')}" unless invalid_attributes.empty?

      @__attributes__ = attributes
      @__cache__ = {}
    end

    def assigned?(attr_name)
      !attribute_key_for(attr_name.to_sym).nil?
    end

    def merge(new_attributes)
      self.class.new __attributes__.merge(new_attributes)
    end

    def eql?(other)
      instance_of?(other.class) && to_h.eql?(other.to_h)
    end

    def ==(other)
      other.kind_of?(self.class) && to_h == other.to_h
    end

    def hash
      [self.class, to_h].hash
    end

    def to_h(options={})
      if options.empty?
        serialized_attributes
      else
        attributes_filter = {only: serialized_attributes.keys, except: []}.merge(options)
        (attributes_filter[:only] - attributes_filter[:except]).each_with_object({}) do |name, hash|
          hash[name] = serialized_attributes[name]
        end
      end

    end

    def to_s
      read_all_assigned_attributes!

      "#{self.class.model_name}[#{__cache__.map { |n,v| "#{n}: #{v.inspect}" }.join(', ')}]"
    end
    alias_method :inspect, :to_s

    private

    attr_reader :__attributes__

    def __cache__
      @__cache__ ||= {}
    end

    def read_all_assigned_attributes!
      self.class.attributes.each do |attribute|
        read_attribute attribute if assigned?(attribute.name) || attribute.default?
      end
    end

    def read_attribute(attribute)
      __cache__[attribute.name] ||= begin
        attribute_key = attribute_key_for attribute.name
        if attribute_key
          cast_attribute attribute.type, __attributes__[attribute_key]
        elsif attribute.default?
          value = attribute.default_value.respond_to?(:call) ? attribute.default_value.call(self) : attribute.default_value
          cast_attribute attribute.type, value
        else
          raise NotAssignedAttributeError, attribute.name
        end
      end
    end

    def cast_attribute(type, value)
      if type.nil?
        value
      elsif type.is_a?(Symbol)
        send type, value
      else
        type.cast value
      end
    end

    def attribute_key_for(attr_name)
      if __attributes__.key?(attr_name)
        attr_name
      elsif __attributes__.key?(attr_name.to_s)
        attr_name.to_s
      else
        nil
      end
    end

    def serialized_attributes
      @serialized_attributes ||= begin
        read_all_assigned_attributes!

        __cache__.each_with_object({}) do |(attr_name, value), hash|
          hash[attr_name] = serialize_value value
        end
      end
    end

    def serialize_value(value)
      case value
        when Model
          value.to_h
        when Array
          value.map { |v| serialize_value v }
        when Hash
          value.each_with_object({}) do |(k,v), h|
            h[k.to_sym] = serialize_value v
          end
        else
          value
      end
    end

  end
end