# frozen_string_literal: true
require 'lug/version'
require 'lug/logger'

# Small utility class for logging messages to stderr or other IO device
#
module Lug
  def self.create(namespace = nil, io = STDERR)
    logger = io.isatty ? TtyLogger.new(io) : Logger.new(io)
    logger.on(namespace)
  end
end
