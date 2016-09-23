# frozen_string_literal: true
require 'lug/version'
require 'lug/logger'

# Small utility class for logging messages to stderr or other IO device
#
module Lug
  def self.create(namespace = nil, io = STDERR)
    device = io.isatty ? TtyDevice.new(io) : Device.new(io)
    Logger.new(device, namespace)
  end
end
