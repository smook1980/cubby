require 'msgpack'

module Cubby
  class Store
    class SerializingProxy < SimpleDelegator
      CUBBY_TYPE_PACK = 'CubbyTypePack'.freeze

      def self.pack(value)
        type = if value.is_a? Cubby::Types::ArrayProxy
                 value.type_name
               else
                 value.class.name
               end

        data = case type
               when 'Date'.freeze
                 [
                   CUBBY_TYPE_PACK,
                   type,
                   value.iso8601
                 ]
               when 'DateTime'.freeze
                 [
                   CUBBY_TYPE_PACK,
                   type,
                   value.iso8601(9)
                 ]
               when 'Symbol'.freeze
                 [
                   CUBBY_TYPE_PACK,
                   type,
                   value.to_s
                 ]
               when 'Array[Cubby::Types::Date]'.freeze
                 [
                   CUBBY_TYPE_PACK,
                   type,
                   value.map(&:iso8601)
                 ]
               when 'Array[Cubby::Types::DateTime]'.freeze
                 [
                   CUBBY_TYPE_PACK,
                   type,
                   value.map { |v| v.iso8601(9) }
                 ]
               when 'Array[Cubby::Types::Symbol]'.freeze
                 [
                   CUBBY_TYPE_PACK,
                   type,
                   value.map(&:to_s)
                 ]
               else
                 value
               end

        data.to_msgpack
      end

      def self.unpack(data)
        raw_value = MessagePack.unpack(data)

        if raw_value.is_a?(Array) && raw_value.first == CUBBY_TYPE_PACK
          restore_type(raw_value[1], raw_value[2])
        else
          raw_value
        end
      end

      def self.restore_type(type, raw_value)
        case type
        when 'Date'.freeze
          Date.iso8601(raw_value)
        when 'DateTime'.freeze
          DateTime.iso8601(raw_value)
        when 'Symbol'.freeze
          raw_value.to_sym
        when 'Array[Cubby::Types::Date]'.freeze
          raw_value.map { |v| Date.iso8601 v }
        when 'Array[Cubby::Types::DateTime]'.freeze
          raw_value.map { |v| DateTime.iso8601 v }
        when 'Array[Cubby::Types::Symbol]'.freeze
          raw_value.map(&:to_sym)
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
