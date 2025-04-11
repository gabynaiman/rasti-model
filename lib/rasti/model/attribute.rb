module Rasti
  class Model
    class Attribute

      attr_reader :name, :type

      def initialize(name, type, options={})
        @name = name
        @type = type
        @options = options
      end

      def default?
        options.key? :default
      end

      def default_value
        options.fetch(:default)
      end

      def option(name)
        options[name]
      end

      def to_s
        "#{self.class}[name: #{name.inspect}, type: #{type.inspect}, options: #{options.inspect}]"
      end
      alias_method :inspect, :to_s

      private

      attr_reader :options

    end
  end
end