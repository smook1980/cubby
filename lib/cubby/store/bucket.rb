require_relative 'bucket_item'

module Cubby
  class Store
    class Bucket
      attr_reader :db

      def initialize(store, model_class)
        @store = store
        @db_name = db_name_for(model_class)
        @model_class = model_class
      end

      def find(id)
        BucketItem.new(self, id)
      end

      private

      def db_name_for(model_class)
        return model_class.name if model_class < Cubby::Model

        fail Cubby::Error, "Non storable type #{model_class} in bucket #{self}.  Type must be a kind of Cubby::Model."
      end
    end
  end
end
