require 'lug'

module Lug
  module Object
    def lug
      defined?(LUG) && LUG
    end
  end

  module Class
    def lug_on(namespace)
      cap_ns = namespace.to_s.split(':').map(&:capitalize).join
      mod_name = :"LugOn#{cap_ns}"

      return const_get(mod_name) if const_defined?(mod_name)
      return unless LUG

      mod = Module.new
      mod.module_eval(%(
        module ClassMethods
          def lug
            LUG.on(#{namespace.inspect})
          end
        end

        def self.included(receiver)
          receiver.extend(ClassMethods)
        end

        def lug
          self.class.lug
        end
      ))
      const_set(mod_name, mod)

      include mod
    end
  end
end

Object.send(:include, Lug::Object)
Class.send(:include, Lug::Class)
