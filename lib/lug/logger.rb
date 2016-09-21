# frozen_string_literal: true
module Lug
  class Device
    attr_reader :io

    def initialize(io)
      @io = io
      @io.sync = true
    end

    def puts(string)
      @io.puts(string)
    end
  end

  # Logger class for non-tty IO devices
  #
  class Logger
    attr_reader :device, :namespace

    # Create a logger with an optional +namespace+ and +io+ device as output
    #
    # @param io [IO, Lug::Device] output device (default: stderr)
    # @param namespace [String, Symbol] (default: nil)
    #
    def initialize(namespace = nil, io_or_dev = STDERR)
      @namespace = namespace.to_s if namespace
      @device = io_or_dev
      @device = Device.new(io_or_dev) unless io_or_dev.is_a?(Device)
    end

    # Clone logger with a custom namespace appended
    #
    # @param namespace [String, Symbol]
    # @return [Lug]
    #
    def on(namespace)
      namespace = "#{@namespace}:#{namespace}" if @namespace
      self.class.new(namespace, @device)
    end

    # Log a message to output device
    #
    # If IO device is a TTY, it will print namespaces with different ANSI
    # colors to make them easily distinguishable.
    #
    # @example
    #   lug = Lug.new
    #   lug << 'This is the message'
    #   # => "This is the message"
    #
    # @example logger with namespace
    #   lug = Lug.new(:myapp)
    #   lug << 'This is the message'
    #   # => "myapp This is the message"
    #
    # @param msg [String]
    # @return [NilClass]
    #
    def log(message = nil)
      message ||= yield if block_given?
      @device.puts(build_line(message))
    end
    alias << log

    private

    def build_line(message, level = nil)
      res = []
      res << Time.now
      res << "[#{@namespace}]" if @namespace
      res << level_text(level) if level
      res << message
      res.join(' '.freeze)
    end
  end
end
