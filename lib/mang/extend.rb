require 'mang'

def Log(namespace)
  mod = Module.new
  mod.module_eval(%(
    module ClassMethods
      def log(*args)
        unless defined?(@@logger)
          @@logger = Mang::Logger.new(#{namespace.inspect})
        end
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
