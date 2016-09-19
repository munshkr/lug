require 'mang/version'
require 'thread'

module Mang
  class Logger
    MSG_COLOR = '0;37'
    COLORS = %w(1;36 1;32 1;33 1;34 1;35 1;31 0;36 0;32 0;33 0;34 0;35 0;31)

    attr_reader   :io, :colors_map
    attr_accessor :namespace

    @@mutex = Mutex.new
    @@colors_map = {}
    @@last_log_ts = nil

    def initialize(namespace = nil, io = STDERR)
      @namespace = namespace
      @io = io
      @io.sync = true
    end

    def log(msg_or_ns, msg = nil)
      # Generate namespace based on parameter and default
      if @namespace
        ns = msg && msg_or_ns
        ns = ns ? "#{@namespace}:#{ns}" : @namespace
      end
      ns = ns && ns.to_s

      msg ||= msg_or_ns

      # Colorize only if @io is a TTY
      if @io.isatty
        if ns
          color = @@mutex.synchronize { color_for(ns) }
          ns = colorize(ns, color, true)
        end
        msg = colorize(msg, MSG_COLOR)
      end

      @@mutex.synchronize do
        now = Time.now
        line = build_line(ns, msg, now)
        @@last_log_ts = now
        @io.puts(line)
      end

      true
    end

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

    def color_for(namespace)
      @@colors_map[namespace] ||= COLORS[@@colors_map.size % COLORS.size]
    end

    def colorize(string, color, bold=false)
      "\e[#{color}m#{string}\e[0m"
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
