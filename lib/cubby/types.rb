module Cubby
  module Types
    class String
      def self.coerce(value)
        return if value.nil?
        String(value)
      end

      def self.literal
        name
      end
    end

    class Boolean
      def self.coerce(value)
        return if value.nil?

        case value
        when 1, '1', 'true', 1.0, 'True', 'TRUE', TrueClass
          TrueClass
        when 0, '0', 'false', 0.0, 'False', 'FALSE', FalseClass
          FalseClass
        else
          fail TypeError("Given value #{value} cannot be converted to boolean")
        end
      end

      def self.literal
        name
      end
    end

    class Integer
      def self.coerce(value)
        return if value.nil?

        return value.to_i if value.respond_to? :to_i
        fail TypeError, "Unable to coerce value: #{value} to Integer."
      end

      def self.literal
        name
      end
    end

    class Float
      def self.coerce(value)
        return if value.nil?

        return value.to_f if value.respond_to? :to_f
        fail TypeError, "Unable to coerce value: #{value} to Float."
      end

      def self.literal
        name
      end
    end

    class Date
      def self.coerce(value)
        return if value.nil?

        if value.respond_to?(:to_date)
          value.to_date
        else
          ::Date.parse(value.to_s)
        end
      end

      def self.literal
        name
      end
    end

    class DateTime
      def self.coerce(value)
        return if value.nil?

        if value.respond_to?(:to_datetime)
          value.to_datetime
        else
          ::DateTime.iso8601(value.to_s)
        end
      end

      def self.literal
        name
      end
    end

    class Array
      def self.[](type)
        new(type)
      end

      attr_reader :type

      def initialize(type)
        @type = type
      end

      def coerce(values, &callback)
        return nil if values.nil?
        vals = values.map { |val| type.coerce val }
        ArrayProxy.new(type, vals).tap { |p| p.before_change &callback }
      end

      def literal
        "#{self.class.name}[#{type.name}]"
      end
    end

    class ArrayProxy < SimpleDelegator
      def initialize(type, values)
        @type = type

        super(values)
      end

      def <<(value)
        @callback.call
        super @type.coerce(value)
      end

      def before_change(&callback)
        @callback = callback
      end

      # TODO: This seems like it would cause false triggers if the operation
      # did not result in a change.
      [
        :delete_at,
        :push,
        :pop,
        :delete_if,
        :fill,
        :flatten!
      ].each do |meth|
        module_eval(<<-METH, __FILE__, __LINE__)
          def #{meth}(*args)
            @callback.call
            super
          end
        METH
      end
    end
  end
end
