require_relative 'naught/null_class_builder'
require_relative 'naught/conversions'
require_relative 'naught/conversions_module'

module Naught
  def self.build(&block)
    builder = NullClassBuilder.new
    builder.customize(&block)
    builder.generate_null_class
  end
end
