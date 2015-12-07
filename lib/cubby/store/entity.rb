module Cubby
  class Store
    EntityNotFound = Class.new(StandardError)
    EntityReadError = Class.new(StandardError)

    class Entity < SimpleDelegator
      class << self
        def find(kvs, id)
          kvs.cursor do |c|
            key, _ = c.set(id)
            fail EntityNotFound, "Model not found for id #{id}" if key != id
            Entity.new(c)
          end
        end

        def each(kvs)
          kvs.cursor do |c|
            c.first
            yield Entity.new(c) while c.get
          end

          nil
        end
      end

      attr_reader :id

      def initialize(cursor)
        super(load!(cursor))
      end

      private

      def load!(cursor)
        key, = cursor.get
        @id, attr = key.split('::')

        # Meta record is stored with only ID and no attribute
        if id.nil? || !attr.nil?
          message = "Cursor not aligned to model meta record! At: #{id} attr: #{attr}"
          fail EntityReadError, message
        end

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
