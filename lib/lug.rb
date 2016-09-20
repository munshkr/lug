# frozen_string_literal: true
require 'lug/version'
require 'lug/logger'
require 'lug/tty_logger'

# Small utility class for logging messages to stderr or other IO device
#
module Lug
  def self.create(namespace = nil, io = STDERR)
    io.isatty ? TtyLogger.new(namespace, io) : Logger.new(namespace, io)
  end
end
