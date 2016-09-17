require 'mang/version'
require 'thread'
require 'colorize'

module Mang
  class Logger
    SOURCE_RE = /<([^>]+)>/

    COLORS = %i(
      light_cyan
      light_green
      light_yellow
      light_blue
      light_magenta
      light_red
      cyan
      green
      yellow
      blue
      magenta
      red
    )

    attr_reader :io, :colors_map

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
          ns = ns.colorize(color: color, mode: :bold)
        end
        msg = msg.colorize(color: :white)
      end

      @@mutex.synchronize do
        now = Time.now
        line = if @io.isatty
          "#{"#{ns} " if ns}#{msg} #{elapsed(now)}"
        else
          "[#{now} #{"[#{ns}] " if ns}#{msg}"
        end
        @@last_log_ts = now
        @io.puts(line)
      end

      true
    end

    def <<(msg)
      log(msg)
    end

    private

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
