# frozen_string_literal: true
require 'thread'

module Lug
  class Device
    attr_reader :io

    def initialize(io = STDERR)
      @io = io
      @io.sync = true

      @enabled_namespaces = []
      enable(ENV['DEBUG'.freeze].to_s) if ENV['DEBUG']
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
    def log(message, namespace = nil)
      line = [
        Time.now,
        $$,
        namespace && "[#{namespace}]",
        message
      ].compact.join(' '.freeze)

      @io.write("#{line}\n")
      nil
    end
    alias << log

    # Clone logger with a namespace appended
    #
    # @param namespace [String, Symbol]
    # @return [Lug]
    #
    def on(namespace)
      Logger.new(self, namespace)
    end

    def enabled_for?(namespace)
      namespace = namespace.to_s
      @enabled_namespaces.any? { |re| namespace =~ re }
    end

    def enable(filter)
      @enabled_namespaces = parse_namespace_filter(filter)
    end

    private

    def parse_namespace_filter(filter)
      res = []
      filter.split(/[\s,]+/).each do |ns|
        next if ns.empty?
        ns = ns.gsub('*'.freeze, '.*?'.freeze)
        res << /^#{ns}$/
      end
      res
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
  class TtyDevice < Device
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
      @prev_time = nil
      @colored_namespaces = {}
    end

    def log(message, namespace = nil)
      @mutex.synchronize do
        now = Time.now
        line = [
          namespace && colorize_namespace(namespace),
          colorize(message, MSG_COLOR),
          elapsed_text(now)
        ].compact.join(' '.freeze)
        @prev_time = now

        @io.write("#{line}\n")
      end
      nil
    end

    private

    def colorize_namespace(namespace)
      @colored_namespaces[namespace] ||=
        colorize(namespace, NS_COLORS[@colored_namespaces.size % NS_COLORS.size])
    end

    def colorize(string, color)
      "\e[#{color}m#{string}\e[0m"
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

  class Logger
    attr_reader :device, :namespace

    # Create a Logger for +device+ within +namespace+
    #
    # @param device [Lug::Device]
    # @param namespace [String, Symbol]
    #
    def initialize(dev_or_io = nil, namespace = nil)
      dev_or_io ||= STDERR
      @device = dev_or_io.is_a?(Device) ? dev_or_io : device_from(dev_or_io)
      @namespace = namespace && namespace.to_s
      @enabled = @device.enabled_for?(@namespace)
    end

    def log(message = nil)
      return unless @enabled
      message ||= yield if block_given?
      @device.log(message, @namespace)
    end
    alias << log

    def on(namespace)
      namespace = [@namespace, namespace].compact.join(':'.freeze)
      Logger.new(@device, namespace)
    end

    def enabled?
      @enabled
    end

    private

    def device_from(io)
      io.isatty ? TtyDevice.new(io) : Device.new(io)
    end
  end
end
