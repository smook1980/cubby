module Cubby
  module Store
    class ModelEnumerable
      def initialize(store, model_class)
        @store = store
        @model_class = model_class
      end
    end
  end
end
