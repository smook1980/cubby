module Cubby
  class Model
    module Storable
      def self.included(base)
        base.extend ClassMethods
      end

      def new_model?
        !(@_persisted ||= false)
      end

      def load!(entity)
        @_id = entity.id
        entity.each { |key, value| send("#{key}=", value) }
        @_persisted = true
        clear_changes_information

        self
      end

      def save
        changeset = changes.each_with_object({}) do |change, changes|
          attribute = change[0]
          _, after = change[1]
          changes[attribute] = after
        end

        self.class.bucket.save(id, changeset)
        @_persisted = true
        changes_applied

        self
      end

      module ClassMethods
        def store
          @store || Cubby.store
        end

        def store=(store)
          @store = store
        end

        def bucket
          store[self]
        end

        def find(id)
          store.with_transaction(read_only: true) do
            new.load! bucket.load(id)
          end
        end

        def all
          enum_for
        end

        def each
          bucket.each { |data| yield new.load!(data) }
        end
      end
    end
  end
end
