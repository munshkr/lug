require 'mang/version'
require 'thread'

module Mang
  # Small utility class for logging messages to stderr or other IO device
  #
  class Logger
    MSG_COLOR = '0;37'.freeze
    COLORS = %w(
      1;36 1;32 1;33 1;34 1;35 1;31
      0;36 0;32 0;33 0;34 0;35 0;31
    ).freeze

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
    def log(msg_or_ns, msg = nil)
      # Generate namespace based on parameter and default
      if @namespace
        ns = msg && msg_or_ns
        ns = ns ? "#{@namespace}:#{ns}" : @namespace
      end
      ns &&= ns.to_s

      msg ||= msg_or_ns

      # Colorize only if @io is a TTY
      ns, msg = colorize_ns_and_msg(ns, msg) if @io.isatty

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

    private

    def build_line(ns, msg, now)
      if @io.isatty
        "#{"#{ns} " if ns}#{msg} #{elapsed(now)}"
      else
        "[#{now} #{"[#{ns}] " if ns}#{msg}"
      end
    end

    def colorize_ns_and_msg(ns, msg)
      if ns
        color = @@mutex.synchronize { color_for(ns) }
        ns = colorize(ns, color)
      end
      msg = colorize(msg, MSG_COLOR)
      [ns, msg]
    end

    def colorize(string, color)
      "\e[#{color}m#{string}\e[0m"
    end

    def color_for(namespace)
      @@colors_map[namespace] ||= COLORS[@@colors_map.size % COLORS.size]
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
  end
end
