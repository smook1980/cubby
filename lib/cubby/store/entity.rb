require_relative 'entity'

module Cubby
  class Store
    class Entity
      attr_reader :bucket, :id

      def initialize(bucket, id)
        @bucket = bucket
        @id = id
      end
    end
  end
end
