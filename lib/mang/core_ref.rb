require 'mang'

def Log(namespace)
  mod = Module.new
  mod.module_eval(%Q(
    refine Object do
      def log(*args)
        @@logger = Mang::Logger.new(#{namespace.inspect}) unless defined?(@@logger)
        block_given? ? @@logger.log(*args) { yield } : @@logger.log(*args)
      end
    end
  ))
  mod
end

Object.const_set(:Log, Log(nil))
