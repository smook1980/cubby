require 'logger'

module Cubby
  class << self
    attr_writer :logger

    def logger
      @logger ||= Logger.new(STDERR)
    end
  end

  module Logable
    %i(info warn error debug).each do |level|
      define_method(level) do |msg = nil, &block|
        if !block.nil?
          Cubby.logger.send(level, self.class.name, &block)
        else
          Cubby.logger.send(level, self.class.name) { msg }
        end
      end
    end
  end
end
