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

        # klass.instance_variable_set('@redis', nil)
        # klass.instance_variable_set('@redis_objects', {})
        # klass.send :include, InstanceMethods
        # klass.extend ClassMethods
      end
    end

    def id
      @_id ||= SecureRandom.uuid
    end
  end
end
