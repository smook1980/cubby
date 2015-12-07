module Cubby
  class Store
    class ModelReader
      attr_accessor :data

      def initialize(cursor)
        model_load!(cursor)
      end

      def data
        @data ||= {}
      end

      private

      def model_load!(cursor)
        key, = cursor.get
        id, attr = key.split('::')

        # Meta record is stored with only ID and no attribute
        if id.nil? || !attr.nil?
          fail ModelReaderError,
               'Cursor not aligned to model meta record!'
        end

        while item =cursor.next
          key, value = item
          record_id, attr = key.split('::')

          break if record_id != id

          data[attr] = value
        end
      end
    end
  end
end
