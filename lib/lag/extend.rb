require 'lag'

def logger_on(namespace, logger_method = :logger)
  mod_name = :"Log_#{namespace.to_s.gsub(':', '__')}"
  return Lag.const_get(mod_name) if Lag.const_defined?(mod_name)

  mod = Module.new
  mod.module_eval(%(
    module ClassMethods
      def #{logger_method}
        @logger ||= Lag::Logger.new(#{namespace.inspect})
      end
    end

    def self.included(receiver)
      receiver.extend(ClassMethods)
    end

    def #{logger_method}
      self.class.#{logger_method}
    end
  ))
  Lag.const_set(mod_name, mod)
  mod
end
