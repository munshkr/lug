require 'mang'

def Log(namespace)
  mod = Module.new
  mod.module_eval(%(
    module ClassMethods
      def log(*args, &block)
        unless defined?(@@logger)
          @@logger = Mang::Logger.new(#{namespace.inspect})
        end
        @@logger.log(*args, &block)
      end
    end

    def log(*args, &block)
      self.class.log(*args, &block)
    end

    def self.included(receiver)
      receiver.extend(ClassMethods)
    end
  ))
  mod
end

Object.const_set(:Log, Log(nil))
