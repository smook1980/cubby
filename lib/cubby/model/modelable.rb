module Cubby
  class Model
    module Modelable
      def self.included(base)
        base.extend ClassMethods
      end

      def attributes
        self.class.fields.each_with_object({}) do |f, a|
          a[f] = send(f)
        end
      end

      module ClassMethods
        def fields
          @_fields ||= []
        end

        def has_one(name, model_type)
          attribute "#{name}_id", Cubby::Types::String

          module_eval(<<-METH, __FILE__, __LINE__)
            def #{name}
              @#{name} ||= begin
                             #{model_type.name}.find(#{name}_id) unless #{name}_id.nil?
                           end
            end

            def #{name}=(value)
              fail TypeError, "Value is not a #{model_type.name}" unless value.is_a?(#{model_type.name}) || value.nil?

              self.#{name}_id = value.nil? ? nil : value.id
              @#{name} = value
            end
          METH
        end

        def attribute(name, type)
          fields << name.to_sym

          module_eval(<<-METH, __FILE__, __LINE__)
            define_attribute_methods :#{name}
            attr_reader :#{name}

            def #{name}=(value)
              value = #{type.literal}.coerce(value) { #{name}_will_change! }

              if !instance_variable_defined?(:@#{name}) || @#{name} != value
              #{name}_will_change!
              @#{name} = value
              end

              value
            end
          METH
        end
      end
    end
  end
end
