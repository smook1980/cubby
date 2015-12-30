require 'cubby/version'
require 'cubby/logger'
require 'cubby/error'
require 'cubby/store'
require 'cubby/model'

module Cubby
  include Logable
  OPEN_WARNING = 'Cubby.open already has been called!  Closing existing store and recreating wtih new config.'.freeze

  class << self
    def store
      fail Cubby::Error, 'You must open the Cubby Store before use!' if @store.nil?
      @store
    end

    # Open the global Cubby::Store at the given path.
    # Call #close! when the store is no longer needed
    # to flush data to disk and cleanup.
    #
    # @see Cubby::Store.initialize
    # @see Cubby::close!
    #
    # @param [String, #read] path path the to directory to contain database files
    # @param [Hash] opts See Cubby::Store.initiailze for options
    def open(path, opts = {})
      Cubby.logger.warn OPEN_WARNING if defined?(@store) && !@store.nil?
      @store = Cubby::Store.new path, opts
      self
    end

    def close!
      @store.close! unless @store.nil?
      @store = nil
      self
    end
  end
end
