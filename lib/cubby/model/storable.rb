module Cubby
  class Model
    module Storable
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def self.store
          @store || Cubby.store
        end

        def self.store=(store)
          @store = store
        end
      end
    end
  end
end
