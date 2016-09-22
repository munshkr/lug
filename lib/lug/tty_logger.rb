# frozen_string_literal: true
require 'lug/logger'
require 'thread'

module Lug
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

    def build_line(message, namespace)
      res = []
      res << colorized(namespace, choose_color(namespace)) if namespace
      res << colorized(message, MSG_COLOR)
      res << elapsed_text
      res.join(' '.freeze)
    end

    def puts(string)
      @mutex.synchronize do
        @prev_time = Time.now
        @io.write("#{string}\n")
      end
      nil
    end

    def colorized(string, color)
      "\e[#{color}m#{string}\e[0m"
    end

    def choose_color(namespace)
      @mutex.synchronize do
        @colors_map[namespace] ||=
          NS_COLORS[@colors_map.size % NS_COLORS.size]
      end
    end

    def elapsed_text
      return '+0ms'.freeze if @prev_time.nil?
      secs = Time.now - @prev_time
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
