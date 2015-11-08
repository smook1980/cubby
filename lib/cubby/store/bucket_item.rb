require_relative 'bucket_item'

module Cubby
  class Store
    class BucketItem
      attr_reader :bucket, :id

      def initialize(bucket, id)
        @bucket = bucket
        @id = id
      end
    end
  end
end
