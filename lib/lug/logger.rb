# frozen_string_literal: true
require 'thread'

module Lug
  # Logger class provides a small logging utility for debugging libraries and
  # applications in Ruby.
  #
  # Usually meassages are grouped hierarchically in *namespaces*, so that
  # different parts of your source code can be logged separately from each
  # other, when needed.
  #
  # By convention, namespaces are lowercase strings separated by a colon ':' to
  # denote a nested namespace.  Regardless, any string formatting can be used.
  #
  # A Logger is associated with a Device, which manages an IO instance.  Lug
  # detects if IO referes to a TTY (Teletype terminal), and uses ANSI colors to
  # format log messages by default. Otherwise, it will use a proper format for
  # log files.
  #
  #     logger = Lug::Logger.new
  #     logger << 'hi there!'
  #
  #     main_logger = logger.on(:main)
  #     main_logger << 'now logging from the "main" namespace'
  #
  # Because Lug is intented to be used to debug both libraries and
  # applications, Lug doesn't print anything unless you correctly set the DEBUG
  # environment variable.  This variable indicates which namespaces you want to
  # log when you run your Ruby script.
  #
  # For example, if your script is:
  #
  #     require 'lug'
  #
  #     logger = Lug::Logger.new
  #     logger.on(:foo) << 'Message from foo'
  #     logger.on(:bar) << 'Message from bar'
  #     logger.on(:baz) << 'Message from baz'
  #
  # Then, running with `DEBUG=foo,bar` will print
  #
  #     foo Message from foo +0ms
  #     bar Message form bar +0ms
  #
  # You can also use wildcars to filter in all messages form a specific
  # namespace and all its nested namespaces.
  #
  #     DEBUG=worker:* ruby process.rb
  #
  #     worker:a I am worker A +0ms
  #     worker:b I am worker B +1ms
  #     worker:b Doing something... +0ms
  #     worker:a Doing something... +2ms
  #     worker:a Done! +963ms
  #     worker:b Done! +2s
  #
  class Logger
    attr_reader :device, :namespace

    # Create a Logger for +device+ within +namespace+
    #
    # When +dev_or_io+ is an IO instance, a Device or TtyDevice will be created
    # with it, depending on IO#isatty. That is, if IO instance refers to a TTY
    # output, it will use a TtyDevice.
    #
    # @param dev_or_io [Lug::Device, IO] device or IO instance
    # @param namespace [String, Symbol]
    #
    def initialize(dev_or_io = nil, namespace = nil)
      dev_or_io ||= STDERR
      @device = dev_or_io.is_a?(Device) ? dev_or_io : Helpers.device_from(dev_or_io)
      @namespace = namespace && namespace.to_s
      @enabled = @device.enabled_for?(@namespace)
    end

    # Log a +message+ to output device
    #
    # @param message [String]
    # @return [NilClass]
    #
    def log(message = nil)
      return unless @enabled
      message ||= yield if block_given?
      @device.log(message, @namespace)
    end
    alias << log

    # Clone logger with the same device and +namespace+
    #
    # @param namespace [String, Symbol]
    # @return [Lug::Logger]
    #
    def on(namespace)
      namespace = [@namespace, namespace].compact.join(':'.freeze)
      Logger.new(@device, namespace)
    end

    # Return true if logger is enabled for current namespace
    #
    # When false, #log won't write anything to its device
    #
    # @return [Boolean]
    #
    def enabled?
      @enabled
    end
  end

  class Device
    attr_reader :io

    # Create a Device associated to an +io+ instance
    #
    # @param io [IO] (default: STDERR)
    #
    def initialize(io = STDERR)
      @io = io
      @io.sync = true

      @enabled_namespaces = []
      enable(ENV['DEBUG'.freeze].to_s) if ENV['DEBUG']
    end

    # Log a +message+ to output device, within a +namespace+
    #
    # @param message [String]
    # @param namespace [String, Symbol] (default: nil)
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

    # Clone logger with the same device and +namespace+ appended
    #
    # @param namespace [String, Symbol]
    # @return [Lug::Logger]
    #
    def on(namespace)
      Logger.new(self, namespace)
    end

    # Decides whether +namespace+ is enabled on this device
    #
    # @param namespace [String, Symbol]
    # @return [Boolean]
    #
    def enabled_for?(namespace)
      ns = namespace.to_s
      @enabled_namespaces.any? { |re| ns =~ re }
    end

    # Updates list of enabled namespaces for this device based on +filter+
    #
    # @param filter [String]
    # @return [Array<Regexp>] list of namespace filter regexps
    #
    def enable(filter)
      @enabled_namespaces = Helpers.parse_namespace_filter(filter)
    end
  end

  # Colors module defines constants of ANSI escape codes used by TtyDevice
  #
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

    # Create a TtyDevice associated to an +io+ instance
    #
    # @param io [IO] (default: STDERR)
    #
    def initialize(io = STDERR)
      super(io)
      @mutex = Mutex.new
      @prev_time = nil
      @colored_namespaces = {}
    end

    # Log a +message+ to output device, within a +namespace+
    #
    # If IO device is a TTY, it will print namespaces with different ANSI
    # colors to make them easily distinguishable.
    #
    # @param message [String]
    # @param namespace [String, Symbol] (default: nil)
    # @return [NilClass]
    #
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
      secs = now - (@prev_time || now)
      if secs >= 60
        "+#{(secs / 60).to_i}m"
      elsif secs >= 1
        "+#{secs.to_i}s"
      else
        "+#{(secs * 1000).to_i}ms"
      end
    end
  end

  module Helpers
    def self.device_from(io)
      io.isatty ? TtyDevice.new(io) : Device.new(io)
    end

    def self.parse_namespace_filter(filter)
      res = []
      filter.split(/[\s,]+/).each do |ns|
        next if ns.empty?
        ns = ns.gsub('*'.freeze, '.*?'.freeze)
        res << /^#{ns}$/
      end
      res
    end
  end
end
