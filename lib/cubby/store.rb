require 'weakref'
require 'lmdb'
require_relative 'store/bucket'
require_relative 'store/model_reader'

module Cubby
  class Store
    extend Forwardable
    include Logable

    DEFAULT_OPTIONS = {

    }.freeze

    class << self
      def finalizer(env)
        proc do
          if !env.respond_to? :weakref_alive? || env.weakref_alive?
            env.close
            Cubby.logger.debug 'Auto clean up of Cubby::Store, you should probably call .close! yourself?'
          end
        end
      end
    end

    attr_reader :path, :env

    # Close all open database files and clean up resources
    #
    # @!method close!
    def_delegator :@env, :close, :close!

    # Get the store config
    #
    # @!method config
    # @return [Hash] store environment properties
    def_delegator :@env, :flags, :config

    # Return a named key value bucket for a given model
    #
    # @!method []
    # @param  [Cubby::Model]
    # @return [Cubby::Database] Reference to named database
    def_delegator :@buckets, :[]

    # Open a model store at the given path.  Call #close! when the store is no
    # longer needed to save data to disk and cleanup.
    #
    # @see Cubby::Store#close!
    #
    # @param [String, #read] path path the to directory to contain database files
    # @param [Hash] opts options for the database environment
    # @option opts [Number] :mode The Posix permissions to set on created files.
    # @option opts [Number] :maxreaders The maximum number of concurrent threads
    #     that can be executing transactions at once.  Default is 126.
    # @option opts [Number] :maxdbs The maximum number of named models in the
    #     store.
    # @option opts [Number] :mapsize The size of the memory map to be allocated
    #     for this store, in bytes.  The memory map size is the
    #     maximum total size of the database.  The size should be a
    #     multiple of the OS page size.  The default size is about
    #     10MiB.
    # @option opts [Boolean] :fixedmap Use a fixed address for the mmap region.
    # @option opts [Boolean] :nosubdir By default, MDB creates its environment
    #     in a directory whose pathname is given in +path+, and creates its data
    #     and lock files under that directory. With this option, path is used
    #     as-is for the database main data file. The database lock file is the
    #     path with "-lock" appended.
    # @option opts [Boolean] :nosync Don't flush system buffers to disk when
    #     committing a transaction. This optimization means a system crash can
    #     corrupt the database or lose the last transactions if buffers are not
    #     yet flushed to disk. The risk is governed by how often the system
    #     flushes dirty buffers to disk and how often {Environment#sync} is
    #     called. However, if the filesystem preserves write order and the
    #     +:writemap+ flag is not used, transactions exhibit ACI (atomicity,
    #     consistency, isolation) properties and only lose D (durability). That
    #     is, database integrity is maintained, but a system crash may undo the
    #     final transactions. Note that +:nosync + :writemap+ leaves the system
    #     with no hint for when to write transactions to disk, unless
    #     {Environment#sync} is called. +:mapasync + :writemap+ may be
    #     preferable.
    # @option opts [Boolean] :rdonly Open the environment in read-only mode.
    #     No write operations will be allowed. MDB will still modify the lock
    #     file - except on read-only filesystems, where MDB does not use locks.
    # @option opts [Boolean] :nometasync Flush system buffers to disk only once
    #     per transaction, omit the metadata flush. Defer that until the system
    #     flushes files to disk, or next non-MDB_RDONLY commit or
    #     {Environment#sync}. This optimization maintains database integrity,
    #     but a system crash may undo the last committed transaction. That is,
    #     it preserves the ACI (atomicity, consistency, isolation) but not D
    #     (durability) database property.
    # @option opts [Boolean] :writemap Use a writeable memory map unless
    #      +:rdonly+ is set. This is faster and uses fewer mallocs, but loses
    #      protection from application bugs like wild pointer writes and other
    #      bad updates into the database. Incompatible with nested transactions.
    # @option opts [Boolean] :mapasync When using +:writemap+, use asynchronous
    #      flushes to disk. As with +:nosync+, a system crash can then corrupt
    #      the database or lose the last transactions. Calling
    #      {Environment#sync} ensures on-disk database integrity until next
    #      commit.
    # @option opts [Boolean] :notls Don't use thread-local storage.
    def initialize(path, opts = {})
      @path = path

      @env = LMDB.new(path, DEFAULT_OPTIONS.merge(opts))
      this = self

      @buckets = Hash.new do |cache, model|
        klass = model_class(model)

        if cache.key? klass
          cache[klass]
        else
          cache[klass] = Store::Bucket.new(this, klass)
        end
      end

      # Attempt to shutdown gracefully even if close! is not called
      at_exit(&self.class.finalizer(WeakRef.new(@env)))
      ObjectSpace.define_finalizer(self, self.class.finalizer(@env))
    end

    # Begin a transaction. Takes a block to run the body of the transaction.
    # A transaction commits when it exits the block successfully. A transaction
    # aborts when it raises an exception or calls Transaction#abort.
    #
    # @param [Boolean #read] read_only Sets transaction to read only when true.  Defaults to false.
    # @yieldparam txn [Transaction] transaction
    def with_transaction(read_only: false, &block)
      @env.transaction(read_only, &block)
    end

    private

    def model_class(model)
      klass = model.class == Class ? model : model.class
      return klass if klass < Cubby::Model

      fail Cubby::Error, "Type #{klass.name} is not a kind of Cubby::Model.  Only types of Cubby::Model may be persisted."
    end
  end
end
