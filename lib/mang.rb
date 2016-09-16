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

    attr_reader :log_device, :colors_map

    def self.for(namespace, dev = STDOUT)
      new(namespace, dev)
    end

    def initialize(namespace = nil, dev = STDOUT)
      @namespace = namespace
      @log_device = LogDevice.new(dev)
      @mutex = Mutex.new
    end

    def log(msg_or_ns, msg = nil)
      ns = (msg && msg_or_ns) || @namespace
      if ns && @log_device.tty?
        ns = ns.to_s
        ns = ns.colorize(color: color_for(ns), mode: :bold)
			end

			if block_given?
				msg = yield
			else
				msg ||= msg_or_ns
			end

      @log_device.puts("#{"#{ns} " if ns}#{msg}")
    end

    def <<(msg)
      log(msg)
    end

    private

    def color_for(namespace)
      @mutex.synchronize do
        @colors_map ||= {}
        @colors_map[namespace] ||= COLORS[@colors_map.size % COLORS.size]
      end
    end
  end

  class LogDevice
    attr_reader :dev

    def initialize(dev = nil)
      @dev = dev
      @mutex = Mutex.new
    end

    def puts(message)
      @mutex.synchronize { @dev.puts(message) }
    end

    def tty?
      @mutex.synchronize { @dev.isatty }
    end
  end
end
