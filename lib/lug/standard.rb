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

    module LoggerMethods
      def log(message = nil, namespace = nil, level = nil)
        message ||= yield if block_given?
        message = "#{LEVEL_TEXT[level]} #{message}" if level
        super(message, namespace)
      end
    end

    module TtyLoggerMethods
      def log(message = nil, namespace = nil, level = nil)
        message ||= yield if block_given?
        if level
          message = "#{colorized(LEVEL_TEXT[level],
                                 LEVEL_COLOR[level])} #{message}"
        end
        super(message, namespace)
      end
    end

    module NamespaceMethods
      def log(message = nil, namespace = nil, _level = nil)
        message ||= yield if block_given?
        namespace = namespace ? "#{@namespace}:#{namespace}" : @namespace
        @logger.log(message, namespace)
      end
    end

    module LoggerNamespaceMethods
      def debug(msg = nil, ns = nil)
        msg ||= yield if block_given?
        log(msg, ns, 0)
      end

      def info(msg = nil, ns = nil)
        msg ||= yield if block_given?
        log(msg, ns, 1)
      end

      def warn(msg = nil, ns = nil)
        msg ||= yield if block_given?
        log(msg, ns, 2)
      end

      def error(msg = nil, ns = nil)
        msg ||= yield if block_given?
        log(msg, ns, 3)
      end

      def fatal(msg = nil, ns = nil)
        msg ||= yield if block_given?
        log(msg, ns, 4)
      end

      def unknown(msg = nil, ns = nil)
        msg ||= yield if block_given?
        log(msg, ns, 5)
      end
    end
  end

  # Overwrite methods on Logger and Namespace classes
  Logger.prepend(Standard::LoggerMethods)
  Namespace.prepend(Standard::NamespaceMethods)
  TtyLogger.prepend(Standard::TtyLoggerMethods)

  # Include extra level methods
  Logger.include(Standard::LoggerNamespaceMethods)
  Namespace.include(Standard::LoggerNamespaceMethods)
end
