module Cubby
  class Model
    module Modelable
      def self.included(base)
        base.extend ClassMethods
      end
    end
  end
end
