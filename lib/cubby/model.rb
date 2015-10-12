module Cubby
  class Model
    class << self
      def inherited(klass)
        # klass.instance_variable_set('@redis', nil)
        # klass.instance_variable_set('@redis_objects', {})
        # klass.send :include, InstanceMethods
        # klass.extend ClassMethods
      end
    end

    module ClassMethods
    end
  end
end
