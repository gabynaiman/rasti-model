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

      def model_name
        name || self.superclass.name
      end

      def to_s
        "#{model_name}[#{attributes.map(&:name).join(', ')}]"
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
      invalid_attributes = attributes.keys.map(&:to_sym) - self.class.attributes.map(&:name)
      raise ArgumentError, "#{self.class.model_name} invalid attributes: #{invalid_attributes.join(', ')}" unless invalid_attributes.empty?

      @attributes = attributes
      @cache = {}
    end

    def merge(new_attributes)
      self.class.new @attributes.merge(new_attributes)
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

      "#{self.class.model_name}[#{@cache.map { |n,v| "#{n}: #{v.inspect}" }.join(', ')}]"
    end
    alias_method :inspect, :to_s

    private

    def read_all_assigned_attributes!
      self.class.attributes.each do |attribute|
        read_attribute attribute if assigned_attribute?(attribute.name) || attribute.default?
      end
    end

    def read_attribute(attribute)
      @cache[attribute.name] ||= begin
        attribute_key = key_for attribute.name
        if attribute_key
          cast attribute, @attributes[attribute_key]
        elsif attribute.default?
          value = attribute.default_value.respond_to?(:call) ? attribute.default_value.call(self) : attribute.default_value
          cast attribute, value
        else
          raise NotAssignedAttributeError, attribute.name
        end
      end
    end

    def cast(attribute, value)
      if attribute.type.nil?
        value
      elsif attribute.type.is_a?(Symbol)
        send attribute.type, value
      else
        attribute.type.cast value
      end
    end

    def assigned_attribute?(attr_name)
      !key_for(attr_name.to_sym).nil?
    end

    def key_for(attr_name)
      if @attributes.key?(attr_name)
        attr_name
      elsif @attributes.key?(attr_name.to_s)
        attr_name.to_s
      else
        nil
      end
    end

    def serialized_attributes
      @serialized_attributes ||= begin
        read_all_assigned_attributes!

        @cache.each_with_object({}) do |(attr_name, value), hash|
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