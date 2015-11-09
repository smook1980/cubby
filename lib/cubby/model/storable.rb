module Cubby
  class Model
    module Storable
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def store
          @store || Cubby.store
        end

        def store=(store)
          @store = store
        end
      end
    end
  end
end
