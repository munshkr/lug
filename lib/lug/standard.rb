# frozen_string_literal: true
require 'lug/logger'

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
      attr_accessor :level_threshold

      def initialize(*args)
        super
        set_level_threshold
      end

      def log(message, namespace = nil, level = nil)
        message = "#{LEVEL_TEXT[level]} #{message}" if level
        super(message, namespace)
      end

      private

      def set_level_threshold
        if ENV['LOG_LEVEL'.freeze]
          level = ENV['LOG_LEVEL'.freeze].to_s.upcase
          @level_threshold = LEVEL_TEXT.index(level)
        end
        @level_threshold ||= 0
      end
    end

    module TtyLoggerMethods
      def log(message, namespace = nil, level = nil)
        if level
          colored_level = colorize(LEVEL_TEXT[level], LEVEL_COLOR[level])
          message = "#{colored_level} #{message}"
        end
        super(message, namespace)
      end
    end

    module NamespaceMethods
      def log(message, level = nil)
        return if level.to_i < logger.level_threshold ||
                  (level.to_i == 0 && !@enabled)
        message ||= yield if block_given?
        @logger.log(message, @namespace, level)
      end
    end

    module LoggerNamespaceMethods
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

  # Overwrite methods on Logger and Namespace classes
  Logger.prepend Standard::LoggerMethods
  Logger.prepend Standard::LoggerNamespaceMethods
  TtyLogger.prepend Standard::TtyLoggerMethods
  Namespace.prepend Standard::NamespaceMethods
  Namespace.prepend Standard::LoggerNamespaceMethods
end
