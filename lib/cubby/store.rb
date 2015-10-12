require 'forwardable'
require 'weakref'
require 'lmdb'

module Cubby
  class Store
    extend Forwardable
    include Logable

    class << self
      def finalize(env)
        proc do
          #$stderr.puts 'Auto clean up of env, you should probably call close yourself?'
          env.close if !env.respond_to? :weakref_alive? || env.weakref_alive?
        end
      end
    end

    def_delegator :@env, :transaction, :with_transaction
    def_delegator :@databases, :[]

    def initialize(path, opts = {})
      @env = LMDB.new(path, opts)

      @databases = Hash.new do |cache, database|
        id = normalized_id(database)
        cache[database] = cache.key?(id) ? cache[id] : cache[id] = Database.new(@env, id)
      end

      at_exit(&self.class.finalize(WeakRef.new(@env)))
      ObjectSpace.define_finalizer(self, self.class.finalize(@env))
    end

    private

    def normalized_id(id)
      if id.class == Class
        id.name.split('::').last.downcase.to_sym
      else
        id.to_sym
      end
    end
  end

  class Database
    def initialize(env, id)
      @env = env
      @db  = env.database(id.to_s.freeze, create: true)
    end
  end

  module Storable
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      attr_reader :store

      def config(path:)
        @store = Cubby::Store.new path
      end
    end
  end
end
