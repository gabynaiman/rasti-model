module Rasti
  class Model
    class NotAssignedAttributeError < StandardError

      attr_reader :attribute

      def initialize(attribute)
        @attribute = attribute
        super "Not assigned attribute #{attribute}"
      end

    end
  end
end