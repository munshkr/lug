# frozen_string_literal: true
require 'lug/logger'

module Lug
  # Standard module extends Lug classes so that it behaves similarly to
  # traditional Logger classes.
  #
  # To use, after requiring this file, call:
  #
  #     Lug::Standard.load!
  #
  # It basically adds methods for writing messages in different severity
  # levels: `#debug`, `info`, `#warn`, `#error`, `#fatal`, `#unknown`.  These
  # methods also accept a block instead of a string, and will call it only if
  # it needs to (in particular, if message level is greater than logger's
  # severity level).
  #
  # By default, severity level is `DEBUG`, but you can set this threshold with
  # the `LOG_LEVEL` environment variable.
  #
  # You can mix these methods with `#log` or `#<<`, but messages logged with
  # `#log` will behave like messages with `DEBUG` level.  This means you will
  # see them *only* if severity level is set to `DEBUG`.
  #
  module Standard
    def self.load!
      # Overwrite methods on Device and Logger classes
      Device.prepend Standard::DeviceMethods, Standard::LoggerDeviceMethods
      TtyDevice.prepend Standard::TtyDeviceMethods
      Logger.prepend Standard::LoggerMethods, Standard::LoggerDeviceMethods
      true
    end

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

    module DeviceMethods
      attr_accessor :level_threshold

      def log(message, namespace = nil, level = nil)
        message = "#{LEVEL_TEXT[level]} #{message}" if level
        super(message, namespace)
      end
      alias << log

      def level_threshold
        @level_threshold ||= begin
          res = nil
          log_level = ENV['LOG_LEVEL'.freeze]
          if log_level
            level = log_level.to_s.upcase
            res = LEVEL_TEXT.index(level)
          end
          res || 0
        end
      end
    end

    module TtyDeviceMethods
      def log(message, namespace = nil, level = nil)
        if level
          colored_level = colorize(LEVEL_TEXT[level], LEVEL_COLOR[level])
          message = "#{colored_level} #{message}"
        end
        super(message, namespace)
      end
      alias << log
    end

    module LoggerMethods
      def log(message, level = nil)
        level_i = level.to_i
        return if level_i < @device.level_threshold ||
                  (level_i == 0 && !@enabled)
        message ||= yield if block_given?
        @device.log(message, @namespace, level)
      end
      alias << log
    end

    module LoggerDeviceMethods
      def debug(msg = nil)
        msg ||= yield if block_given?
        log(msg, 0)
      end

      def info(msg = nil)
        msg ||= yield if block_given?
        log(msg, 1)
      end

      def warn(msg = nil)
        msg ||= yield if block_given?
        log(msg, 2)
      end

      def error(msg = nil)
        msg ||= yield if block_given?
        log(msg, 3)
      end

      def fatal(msg = nil)
        msg ||= yield if block_given?
        log(msg, 4)
      end

      def unknown(msg = nil)
        msg ||= yield if block_given?
        log(msg, 5)
      end
    end
  end
end
