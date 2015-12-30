module Cubby
  class Store
    EntityNotFound  = Class.new(StandardError)
    EntityReadError = Class.new(StandardError)

    class Entity < SimpleDelegator
      class << self
        def find(kvs, id)
          kvs.cursor do |c|
            key, _ = c.set(id)
            fail EntityNotFound, "Model not found for id #{id}" if key != id
            EntityReader.read_entity!(c)
          end
        end

        def each(kvs)
          kvs.cursor do |c|
            c.first
            yield EntityReader.read_entity!(c) while c.get
          end

          nil
        end
      end

      attr_reader :id, :metadata

      def initialize(id, metadata, data)
        @id = id
        @metadata = metadata
        super(data)
      end
    end

    class EntityReader
      attr_reader :id, :metadata, :data

      def self.read_entity!(cursor)
        reader = new.tap { |er| er.read!(cursor) }

        Entity.new(reader.id, reader.metadata, reader.data)
      end

      def read!(cursor)
        @id, @metadata = read_metadata!(cursor)
        @data = read_data!(cursor)
        self
      end

      private

      def read_metadata!(cursor)
        key, metadata = cursor.get
        id, attr = key.split('::')

        # Meta record is stored with only ID and no attribute
        if id.nil? || !attr.nil?
          message = "Cursor not aligned to model meta record! At: #{id} attr: #{attr}"
          fail EntityReadError, message
        end

        [id, metadata]
      end

      def read_data!(cursor)
        data = {}

        while item = cursor.next
          key, value = item
          record_id, attr = key.split('::')

          break if record_id != id

          data[attr] = value
        end

        data
      end
    end
  end
end
