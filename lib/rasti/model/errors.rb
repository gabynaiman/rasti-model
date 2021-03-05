module Rasti
  class Model

    class NotAssignedAttributeError < StandardError

      attr_reader :attribute

      def initialize(attribute)
        @attribute = attribute
      end

      def message
        "Not assigned attribute #{attribute}"
      end

    end

    class InvalidAttributesError < StandardError

      attr_reader :attributes

      def initialize(attributes)
        @attributes = attributes
      end

      def message
        "Invalid attributes: #{attributes.join(', ')}"
      end

    end

  end
end