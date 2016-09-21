module Lug
  module Standard
    LEVEL_TEXT = [
      'DEBUG'.freeze,
      'INFO'.freeze,
      'WARN'.freeze,
      'ERROR'.freeze,
      'FATAL'.freeze,
      'UNKNOWN'.freeze
    ].freeze

    LEVEL_COLOR = [
      Colors::CYAN,
      Colors::GREEN,
      Colors::YELLOW,
      Colors::RED,
      Colors::LIGHT_RED,
      Colors::MAGENTA
    ].freeze

    def debug(msg = nil)
      msg ||= yield if block_given?
      @device.puts(build_line(msg, 0))
    end

    def info(msg = nil)
      msg ||= yield if block_given?
      @device.puts(build_line(msg, 1))
    end

    def warn(msg = nil)
      msg ||= yield if block_given?
      @device.puts(build_line(msg, 2))
    end

    def error(msg = nil)
      msg ||= yield if block_given?
      @device.puts(build_line(msg, 3))
    end

    def fatal(msg = nil)
      msg ||= yield if block_given?
      @device.puts(build_line(msg, 4))
    end

    def unknown(msg = nil)
      msg ||= yield if block_given?
      @device.puts(build_line(msg, 5))
    end
  end
end
