require 'mang'

def Log(namespace)
  mod = Module.new
  mod.module_eval(%Q(
    module ClassMethods
      def log(*args)
        @@logger = Mang::Logger.new(#{namespace.inspect}) unless defined?(@@logger)
        block_given? ? @@logger.log(*args) { yield } : @@logger.log(*args)
      end
    end

    def log(*args)
      self.class.log(*args)
    end

    def self.included(receiver)
      receiver.extend(ClassMethods)
    end
  ))
  mod
end

Object.const_set(:Log, Log(nil))
