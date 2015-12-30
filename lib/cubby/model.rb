require 'forwardable'
require 'active_model'
require_relative 'types'
require_relative 'model/storable'
require_relative 'model/modelable'

module Cubby
  class Model
    EXTENSIONS = [
      ActiveModel::Dirty,
      Storable,
      Modelable
    ].freeze

    class << self
      def inherited(klass)
        klass.class_eval do
          EXTENSIONS.each { |extension| include extension }
        end
      end
    end

    def id
      @_id ||= SecureRandom.uuid.freeze
    end

    def hash
      id.hash
    end

    def ==(other)
      super || other.instance_of?(self.class) && other.id == id
    end

    alias_method :eql?, :==
  end
end
