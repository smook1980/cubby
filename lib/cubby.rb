require 'cubby/version'
require 'cubby/logger'
require 'cubby/store'
require 'cubby/model'

module Cubby
  include Logable
  include Storable
end
