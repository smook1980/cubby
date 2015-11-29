module Cubby
  class Store
    EntityNotFound = Class.new(StandardError)

    class Entity < SimpleDelegator
      attr_reader :bucket, :id

      def initialize(bucket, id)
        @bucket = bucket
        @id = id
        super(load!)
      end

      private

      def load!
        data = { }

        bucket.kvs.cursor do |c|
          key, _ = c.set(id)
          fail EntityNotFound, "Model not found for id #{id}" if key != id

          while item = c.next
            key, value = item
            record_id, attr = split_key(key)
            break if record_id != id
            data[attr] = value
          end
        end

        data
      end

      def split_key(key)
        key.split('::')
      end
    end
  end
end
