# frozen_string_literal: true
require 'mang/version'
require 'thread'

module Mang
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

  # Small utility class for logging messages to stderr or other IO device
  #
  class Logger
    MSG_COLOR = Colors::WHITE

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
      Colors::RED,
    ]

    LEVEL_TEXT = [
      'DEBUG'.freeze,
      'INFO'.freeze,
      'WARN'.freeze,
      'ERROR'.freeze,
      'FATAL'.freeze,
      'UNKNOWN'.freeze,
    ]

    LEVEL_COLOR = [
      Colors::CYAN,
      Colors::GREEN,
      Colors::YELLOW,
      Colors::RED,
      Colors::LIGHT_RED,
      Colors::MAGENTA,
    ]

    attr_reader :io, :namespace

    @@mutex = Mutex.new
    @@colors_map = {}
    @@last_log_ts = nil

    # Create a Logger with an optional +namespace+ and +io+ device as output
    #
    # @param namespace [String]
    # @param io [IO] output device
    #
    def initialize(namespace = nil, io = STDERR)
      @namespace = namespace
      @io = io
      @io.sync = true
    end

    # Log a message to output device
    #
    # If IO device is a TTY, it will print namespaces with different ANSI
    # colors to make them apart.
    #
    # @example Without a custom namespace
    #   logger = Logger.new('myapp')
    #   logger.log 'This is the message'
    #   # => "myapp This is the message"
    #
    # @example With a custom namespace
    #   logger = Logger.new('myapp')
    #   logger.log 'route', 'This is the message'
    #   # => "myapp:route This is the message"
    #
    # @param msg_or_ns [String] message, or namespace if +msg+ is present
    # @param msg [String]
    # @return [NilClass]
    #
    def log(msg_or_ns = nil, msg = nil)
      # Generate namespace based on parameter and default
      if @namespace
        ns = msg && msg_or_ns
        ns = ns ? "#{@namespace}:#{ns}" : @namespace
      end
      ns &&= ns.to_s

      msg ||= block_given? ? yield : msg_or_ns

      # Colorize only if @io is a TTY
      ns, msg = colorized_ns_and_msg(ns, msg) if @io.isatty

      @@mutex.synchronize do
        now = Time.now
        line = build_line(ns, msg, now)
        @@last_log_ts = now
        @io.puts(line)
      end

      nil
    end

    # @see {#log}
    def <<(msg)
      log(msg)
    end

    def debug(*args, &block)
      log_with_level(0, *args, &block)
    end

    def info(*args, &block)
      log_with_level(1, *args, &block)
    end

    def warn(*args, &block)
      log_with_level(2, *args, &block)
    end

    def error(*args, &block)
      log_with_level(3, *args, &block)
    end

    def fatal(*args, &block)
      log_with_level(4, *args, &block)
    end

    def unknown(*args, &block)
      log_with_level(5, *args, &block)
    end

    private

    def build_line(ns, msg, now)
      if @io.isatty
        "#{"#{ns} " if ns}#{msg} #{elapsed(now)}"
      else
        "#{now} #{"[#{ns}] " if ns}#{msg}"
      end
    end

    def colorized_ns_and_msg(ns, msg)
      if ns
        color = @@mutex.synchronize { color_for(ns) }
        ns = colorized(ns, color)
      end
      msg = colorized(msg, MSG_COLOR)
      [ns, msg]
    end

    def colorized_level(level)
      if @io.isatty
        colorized(LEVEL_TEXT[level], LEVEL_COLOR[level])
      else
        LEVEL_TEXT[level]
      end
    end

    def colorized(string, color)
      "\e[#{color}m#{string}\e[0m"
    end

    def color_for(namespace)
      @@colors_map[namespace] ||= NS_COLORS[@@colors_map.size % NS_COLORS.size]
    end

    def elapsed(now)
      return unless @@last_log_ts
      secs = now - @@last_log_ts
      if secs >= 60
        "+#{(secs / 60).to_i}m"
      elsif secs >= 1
        "+#{secs.to_i}s"
      else
        "+#{(secs * 1000).to_i}ms"
      end
    end

    def log_with_level(level, msg = nil, &block)
      msg ||= yield if block_given?
      log(nil, "#{colorized_level(level)} #{colorized(msg, MSG_COLOR)}")
    end
  end
end
