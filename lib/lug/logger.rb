# frozen_string_literal: true
module Lug
  class Logger
    attr_reader :io

    def initialize(io = STDERR)
      @io = io
      @io.sync = true
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
    def log(message = nil, namespace = nil)
      message ||= yield if block_given?
      print_line(message, namespace)
    end
    alias << log

    # Clone logger with a namespace appended
    #
    # @param namespace [String, Symbol]
    # @return [Lug]
    #
    def on(namespace)
      Namespace.new(namespace, self)
    end

    private

    def print_line(message, namespace)
      line = [
        Time.now,
        namespace && "[#{namespace}]",
        message
      ].compact.join(' '.freeze)

      @io.write("#{line}\n")
      nil
    end
  end

  class Namespace
    attr_reader :logger, :namespace

    # Create a Namespace from +namespace+ associated to +logger+
    #
    # @param namespace [String, Symbol]
    # @param logger [Lug::Logger]
    #
    def initialize(namespace, logger)
      @namespace = namespace.to_s
      @logger = logger
    end

    def log(message = nil, namespace = nil)
      message ||= yield if block_given?
      namespace = namespace ? "#{@namespace}:#{namespace}" : @namespace
      @logger.log(message, namespace)
    end
    alias << log

    def on(namespace)
      Namespace.new("#{@namespace}:#{namespace}", @logger)
    end
  end
end
