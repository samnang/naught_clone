module Naught
  class NullClassBuilder
    def initialize
      @base_class = BasicObject
      @interface_defined = false
      @stub_strategy     = :stub_method_returning_nil
    end

    def customize(&customization_block)
      return unless customization_block

      customization_module.module_exec(self, &customization_block)
    end

    def generate_null_class
      null_class = build_basic_null_class
      respond_to_any_messages unless @interface_defined

      tasks.each {|t| t.call(null_class) }

      null_class
    end

    def define_explicit_conversions
      defer do |null_class|
        null_class.send(:include, ExplicitConversions)
      end
    end

    def define_implicit_conversions
      defer do |null_class|
        null_class.send(:include, ImplicitConversions)
      end
    end

    def singleton
      defer do |null_class|
        require 'singleton'

        null_class.class_eval do
          include Singleton
        end
      end
    end

    def black_hole
      @stub_strategy = :stub_method_returning_self
    end

    def mimic(class_to_mimic, include_super: true)
      @base_class = Object
      @interface_defined = true

      defer do |null_class|
        methods_to_stub = class_to_mimic.instance_methods(include_super) - Object.instance_methods
        methods_to_stub.each do |name|
          stub_method(null_class, name)
        end

        null_class.class_eval do
          define_method(:inspect) do
            "<null:Naught::#{class_to_mimic}>"
          end
        end
      end
    end

    def impersonate(class_to_impersonate, options={})
      mimic(class_to_impersonate, options)
      @base_class = class_to_impersonate
    end

    def traceable
      defer do |null_class|
        null_class.class_eval do
          attr_reader :__file__, :__line__

          def initialize(caller: Kernel.caller_locations)
            location = caller.first
            @__file__ = location.path
            @__line__ = location.lineno
          end
        end
      end
    end

    def null_equivalents
      @null_equivalents ||= [nil]
    end

    private

    def defer(&block)
      tasks << block
    end

    def tasks
      @tasks ||= []
    end

    def customization_module
      @customization_module ||= Module.new
    end

    def build_basic_null_class
      null_class = Class.new(@base_class) do
        klass = self
        define_method(:class) { klass }
        def inspect; '<null>' end
      end

      add_customize_module(null_class)
      add_conversions_module(null_class)

      null_class
    end

    def add_customize_module(null_class)
      null_class.const_set :Customizations, customization_module
      null_class.send(:prepend, customization_module)
    end

    def add_conversions_module(null_class)
      null_class.const_set :Conversions, ConversionsModule.new(null_class, null_equivalents)
    end

    def respond_to_any_messages
      defer do |null_class|
        stub_method(null_class, :method_missing)
        null_class.class_eval do
          def respond_to?(*); true end
        end
      end
    end

    def stub_method(subject, name)
      send(@stub_strategy, subject, name)
    end

    def stub_method_returning_nil(klass, name)
      klass.class_eval do
        define_method(name){|*| nil }
      end
    end

    def stub_method_returning_self(klass, name)
      klass.class_eval do
        define_method(name){|*| self }
      end
    end
  end
end
