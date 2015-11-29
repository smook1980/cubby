require 'msgpack'

module Cubby
  class Store
    class SerializingProxy < SimpleDelegator
      def []=(key, value)
        put(key, value)
      end

      def put(key, value, opts = {})
        super(key, value.to_msgpack, opts)
      end

      def [](key)
        get(key)
      end

      def get(key)
        value = super(key)
        value.nil? ? value : MessagePack.unpack(value)
      end

      def cursor
        super do |c|
          yield CursorProxy.new(c)
        end
      end

      class CursorProxy < SimpleDelegator
        def set(key)
          item = super(key)
          return if item.nil?

          [
            item[0],
            item[1].nil? ? nil : MessagePack.unpack(item[1])
          ]
        end

        def next
          item = super
          return if item.nil?

          [
            item[0],
            item[1].nil? ? nil : MessagePack.unpack(item[1])
          ]
        end
      end
    end
  end
end
