require 'mang'

module Mang::Object
  def log(*args)
    @@logger = Mang::Logger.new unless defined?(@@logger)
    block_given? ? @@logger.log(*args) { yield } : @@logger.log(*args)
  end
end

class Object
  include Mang::Object
end
