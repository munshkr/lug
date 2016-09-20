require 'mang'

def logger_on(namespace, logger_method = :logger)
  mod_name = :"Log_#{namespace}"
  return Mang.const_get(mod_name) if Mang.const_defined?(mod_name)

  mod = Module.new
  mod.module_eval(%(
    module ClassMethods
      def #{logger_method}
        @logger ||= Mang::Logger.new(#{namespace.inspect})
      end
    end

    def self.included(receiver)
      receiver.extend(ClassMethods)
    end

    def #{logger_method}
      self.class.#{logger_method}
    end
  ))
  Mang.const_set(:"Log_#{namespace}", mod)
  mod
end
