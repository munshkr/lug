require 'mang/version'
require 'thread'
require 'colorize'

module Mang
  class Logger
    include MonitorMixin

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

    def initialize(namespace = nil, io = STDERR)
      @namespace = namespace
      @io = io
      @io.sync = true

      @@mutex = Mutex.new unless defined?(@@mutex)
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
        ns = ns && ns.colorize(color: self.class.color_for(ns), mode: :bold)
        msg = msg.colorize(color: :white)
      end

      @io.puts("#{"#{ns} " if ns}#{msg}")
    end

    def <<(msg)
      log(msg)
    end

    private

    def self.color_for(namespace)
      @@mutex.synchronize do
        @@colors_map = {} unless defined?(@@colors_map)
        @@colors_map[namespace] ||= COLORS[@@colors_map.size % COLORS.size]
      end
    end
  end
end

def Log(namespace)
  mod = Module.new
  mod.module_eval(%Q(
    def log(*args)
      @@logger = Mang::Logger.new(#{namespace.inspect}) unless defined?(@@logger)
      block_given? ? @@logger.log(*args) { yield } : @@logger.log(*args)
    end
  ))
  mod
end

Object.const_set(:Log, Log(nil))
