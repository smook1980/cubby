require 'cubby/version'
require 'cubby/logger'
require 'cubby/error'
require 'cubby/store'
require 'cubby/model'

module Cubby
  include Logable

  class << self
    attr_reader :store

    def config(path, opts = {})
      @store = Cubby::Store.new path, opts
    end
  end
end
