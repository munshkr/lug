# frozen_string_literal: true
require 'thread'

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
        $$,
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

  module Colors
    DEFAULT       = '0;0'.freeze
    BLACK         = '0;30'.freeze
    RED           = '0;31'.freeze
    GREEN         = '0;32'.freeze
    YELLOW        = '0;33'.freeze
    BLUE          = '0;34'.freeze
    MAGENTA       = '0;35'.freeze
    CYAN          = '0;36'.freeze
    WHITE         = '0;37'.freeze
    LIGHT_BLACK   = '1;30'.freeze
    LIGHT_RED     = '1;31'.freeze
    LIGHT_GREEN   = '1;32'.freeze
    LIGHT_YELLOW  = '1;33'.freeze
    LIGHT_BLUE    = '1;34'.freeze
    LIGHT_MAGENTA = '1;35'.freeze
    LIGHT_CYAN    = '1;36'.freeze
    LIGHT_WHITE   = '1;37'.freeze
  end

  # Logger class for tty IO devices
  #
  # Output is colorized with standard ANSI escape codes
  #
  class TtyLogger < Logger
    NS_COLORS = [
      Colors::LIGHT_CYAN,
      Colors::LIGHT_GREEN,
      Colors::LIGHT_YELLOW,
      Colors::LIGHT_BLUE,
      Colors::LIGHT_MAGENTA,
      Colors::LIGHT_CYAN,
      Colors::LIGHT_RED,
      Colors::CYAN,
      Colors::GREEN,
      Colors::YELLOW,
      Colors::BLUE,
      Colors::MAGENTA,
      Colors::CYAN,
      Colors::RED
    ].freeze

    MSG_COLOR = Colors::WHITE

    def initialize(io = STDERR)
      super(io)
      @mutex = Mutex.new
      @colors_map = {}
      @prev_time = nil
    end

    private

    def print_line(message, namespace)
      @mutex.synchronize do
        now = Time.now
        line = [
          namespace && colorized(namespace, choose_color(namespace)),
          colorized(message, MSG_COLOR),
          elapsed_text(now)
        ].compact.join(' '.freeze)
        @prev_time = now

        @io.write("#{line}\n")
      end
      nil
    end

    def colorized(string, color)
      "\e[#{color}m#{string}\e[0m"
    end

    def choose_color(namespace)
      @colors_map[namespace] ||=
        NS_COLORS[@colors_map.size % NS_COLORS.size]
    end

    def elapsed_text(now)
      return '+0ms'.freeze if @prev_time.nil?
      secs = now - @prev_time
      if secs >= 60
        "+#{(secs / 60).to_i}m"
      elsif secs >= 1
        "+#{secs.to_i}s"
      else
        "+#{(secs * 1000).to_i}ms"
      end
    end
  end
end
