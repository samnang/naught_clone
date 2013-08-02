module Naught
  class ConversionsModule < Module
    attr_reader :null_class, :null_equivalents

    def initialize(null_class, null_equivalents)
      @null_class = null_class
      @null_equivalents = null_equivalents

      super() do
        %i[Null Maybe Just Actual].each do |method_name|
          define_method(method_name, &method(method_name))
        end
      end
    end
    
    def Null(object=:nothing_passed)
      case object
      when null_class then object
      when :nothing_passed, *null_equivalents
        null_class.new(caller: Kernel.caller_locations(1))
      else raise ArgumentError, "#{object.inspect} is not null!"
      end
    end
    
    def Maybe(object=nil, &block)
      object = block ? block.call : object
      case object
      when null_class then object
      when *null_equivalents
        null_class.new(caller: Kernel.caller_locations(1))
      else
        object
      end
    end

    def Just(object=nil, &block)
      object = block ? block.call : object
      case object
      when null_class, *null_equivalents
        raise ArgumentError, "Null value: #{object.inspect}"
      else
        object
      end
    end

    def Actual(object=nil, &block)
      object = block ? block.call : object
      case object
      when null_class then nil
      else
        object
      end
    end
  end
end
