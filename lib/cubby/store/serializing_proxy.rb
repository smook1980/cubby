require 'msgpack'

module Cubby
  class Store
    class SerializingProxy < SimpleDelegator
      CUBBY_TYPE_PACK = 'CubbyTypePack'.freeze

      def self.pack(value)
        case value.class.name
        when Date.name
          [CUBBY_TYPE_PACK, Date.name, value.iso8601].to_msgpack
        when DateTime.name
          [CUBBY_TYPE_PACK, DateTime.name, value.iso8601(9)].to_msgpack
        when Symbol.name
          [CUBBY_TYPE_PACK, value.class.name, value.to_s].to_msgpack
        else
          value.to_msgpack
        end
      end

      def self.unpack(data)
        mark_or_value, type, string_value = MessagePack.unpack(data)
        mark_or_value == CUBBY_TYPE_PACK ? restore_type(type, string_value) : mark_or_value
      end

      def self.restore_type(type, string_value)
        case type
        when Date.name
          Date.iso8601(string_value)
        when DateTime.name
          DateTime.iso8601(string_value)
        when Symbol.name
          string_value.to_sym
        end
      end

      def []=(key, value)
        put(key, value)
      end

      def put(key, value, opts = {})
        super(key, SerializingProxy.pack(value), opts)
      end

      def [](key)
        get(key)
      end

      def get(key)
        value = super(key)
        value.nil? ? value : SerializingProxy.unpack(value)
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
            item[1].nil? ? nil : SerializingProxy.unpack(item[1])
          ]
        end

        def next
          item = super
          return if item.nil?

          [
            item[0],
            item[1].nil? ? nil : SerializingProxy.unpack(item[1])
          ]
        end
      end
    end
  end
end
