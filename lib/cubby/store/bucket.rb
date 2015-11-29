require_relative 'entity'
require_relative 'serializing_proxy'

module Cubby
  class Store
    # A bucket represents a namespaced key value store for a type of Model
    # @api private
    class Bucket
      attr_reader :kvs, :namespace, :model_class

      def initialize(store, model_class)
        @model_class = model_class
        @namespace = namespace_for(model_class)
        @store = store
        @kvs = SerializingProxy.new(
          store.env.database(namespace, create: true))
      end

      def load(id)
        Entity.new(self, id)
      end

      def save(id, changeset)
        @store.with_transaction do
          meta = kvs[id]
          if meta.nil?
            kvs[id] = "meta"
          else
            kvs[id] = "meta"
          end

          changeset.each do |attribute, value|
            set id, attribute, value
          end
        end
      end

      def get(id, attribute)
      end

      def set(id, attribute, value)
        kvs[key_for(id, attribute)] = value
      end

      private

      def key_for(id, attr)
        "#{id}::#{attr}"
      end

      def namespace_for(model_class)
        return model_class.name if model_class < Cubby::Model

        fail Cubby::Error, "Non storable type #{model_class} in bucket #{self}.  Type must be a kind of Cubby::Model."
      end
    end
  end
end
