require 'virtus'
require_relative 'model/storable'

module Cubby
  class Model
    EXTENSIONS = [
      Storable
    ].freeze

    class << self
      def inherited(klass)
        EXTENSIONS.each { |extension| klass.send :include, extension }

        # klass.instance_variable_set('@redis', nil)
        # klass.instance_variable_set('@redis_objects', {})
        # klass.send :include, InstanceMethods
        # klass.extend ClassMethods
      end
    end
  end
end
