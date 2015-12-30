$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'forwardable'
require 'cubby'
require 'ffaker'
require 'rspec'

module SpecHelper
  class << self
    attr_accessor :tmpdir

    def reset!
      @test_user_model = nil
      @test_store.close!
      @test_store = nil
      FileUtils.remove_entry @tmpdir
      @tmpdir = nil
    rescue => e
      $stderr.puts "Failed to clean up after test!\n #{e}"
    end

    def create_test_store(opts = {})
      @test_store.close! unless @test_store.nil?
      @test_store = Cubby::Store.new(tmpdir, opts)
    end

    def test_store
      @test_store ||= create_test_store
    end

    def build_user_instance
      test_user_model.new.tap do |m|
        m.first_name = FFaker::Name.first_name
        m.last_name = FFaker::Name.last_name
        m.birthdate = FFaker::Time.date
        m.phone = FFaker::PhoneNumber.phone_number
        m.height = rand(120)
        m.weight = rand(220)
      end
    end

    def test_user_model
      @test_user_model ||= Class.new(Cubby::Model) do
        def self.name
          'User'
        end

        attribute :first_name, ::Cubby::Types::String
        attribute :last_name, ::Cubby::Types::String
        attribute :birthdate, ::Cubby::Types::Date
        attribute :phone, ::Cubby::Types::String
        attribute :height, ::Cubby::Types::Float
        attribute :weight, ::Cubby::Types::Integer
        attribute :minion_ids, ::Cubby::Types::Array[::Cubby::Types::String]
      end
    end
  end

  module FeatureHelper
    extend Forwardable

    def_delegator :helpers, :test_store, :store
    def_delegator :helpers, :reset!, :reset!

    def build_address(
      address: FFaker::AddressUS.street_address,
      city: FFaker::AddressUS.city,
      state: FFaker::AddressUS.state,
      zip: FFaker::AddressUS.zip_code)

      Address.new.tap do |a|
        a.address = address
        a.city = city
        a.state = state
        a.zip = zip
      end
    end

    def build_user(address: nil)
      address ||= Address.build_address
      fail 'do it now!'
    end

    class Address < Cubby::Model
      attribute :address, ::Cubby::Types::String
      attribute :city, ::Cubby::Types::String
      attribute :state, ::Cubby::Types::String
      attribute :zip, ::Cubby::Types::Integer
    end

    class UserModel < Cubby::Model
      attribute :first_name, ::Cubby::Types::String
      attribute :last_name, ::Cubby::Types::String
      attribute :birthdate, ::Cubby::Types::Date
      attribute :phone, ::Cubby::Types::String

      has_one :address, Address
    end
  end
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  # These two settings work together to allow you to limit a spec run
  # to individual examples or groups you care about by tagging them with
  # `:focus` metadata. When nothing is tagged with `:focus`, all examples
  # get run.
  config.filter_run :focus
  config.run_all_when_everything_filtered = true
  config.warnings = true

  config.default_formatter = 'doc' if config.files_to_run.one?

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = :random

  # Seed global randomization in this process using the `--seed` CLI option.
  # Setting this allows you to use `--seed` to deterministically reproduce
  # test failures related to randomization by passing the same `--seed` value
  # as the one that triggered the failure.
  Kernel.srand config.seed

  config.around do |spec|
    Dir.mktmpdir { |tmpdir| SpecHelper.tmpdir = tmpdir; spec.run }
  end
end
