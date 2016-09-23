# frozen_string_literal: true
require 'lug/logger'

module Lug
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
          if ENV['LOG_LEVEL'.freeze]
            level = ENV['LOG_LEVEL'.freeze].to_s.upcase
            res = LEVEL_TEXT.index(level)
          end
          res ||= 0
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
        return if level.to_i < @device.level_threshold ||
                  (level.to_i == 0 && !@enabled)
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
