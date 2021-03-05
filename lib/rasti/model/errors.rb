module Rasti
  class Model

    class NotAssignedAttributeError < StandardError

      attr_reader :attribute

      def initialize(attribute)
        @attribute = attribute
        super "Not assigned attribute #{attribute}"
      end

    end

    class UnexpectedAttributesError < StandardError

      attr_reader :attributes

      def initialize(attributes)
        @attributes = attributes
        super "Unexpected attributes: #{attributes.join(', ')}"
      end

    end

  end
end