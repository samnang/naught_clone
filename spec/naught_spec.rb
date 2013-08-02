require_relative '../lib/naught'

describe Naught do
  let(:null_class) { Naught.build }
  subject(:null) { null_class.new }
  
  it 'knows its own class' do
    expect(null.class).to eq(null_class)
  end

  it 'responds to any messages' do
    expect(null.info).to be_nil
    expect(null.foobar).to be_nil
    expect(null.to_s).to be_nil
  end

  it 'reports that it responds to any messages' do
    expect(null).to respond_to(:info)
    expect(null).to respond_to(:foobar)
    expect(null).to respond_to(:to_s)
    expect(null).to respond_to(:class)
  end
end

describe 'explicitly convertable null object' do
  subject(:null) { null_class.new }
  let(:null_class) { 
    Naught.build do |b|
      b.define_explicit_conversions
    end
  }

  it 'defines common explicit conversions to return zero values' do
    expect(null.to_s).to eql('')
    expect(null.to_a).to eql([])
    expect(null.to_i).to eql(0)
    expect(null.to_f).to eql(0.0)
    expect(null.to_c).to eq(Complex(0))
    expect(null.to_r).to eq(Rational(0))
    expect(null.to_h).to eq({})
  end
end

describe 'implicitly convertable null object' do
  subject(:null) { null_class.new }
  let(:null_class) { 
    Naught.build do |b|
      b.define_implicit_conversions
    end
  }

  it 'implicitly converts to an empty array' do
    expect(null.to_ary).to eql([])
  end

  it 'implicitly converts to an empty string' do
    expect(null.to_str).to eql('')
  end

  it 'implicitly splats the same way an empty array does' do
    a, b = null

    expect(a).to be_nil
    expect(b).to be_nil
  end
end

describe 'singleton null object' do
  let(:null_class) { 
    Naught.build do |b|
      b.singleton
    end
  }

  it 'does not respond to .new' do
    expect(null_class).to_not respond_to(:new)
  end

  it 'has only one instance' do
    null_1 = null_class.instance
    null_2 = null_class.instance

    expect(null_1).to be(null_2)
  end

  it 'can be duplicated or cloned' do
    null = null_class.instance

    expect(null.clone).to be_nil
    expect(null.dup).to be_nil
  end
end

describe 'black hole null object' do
  subject(:null) { null_class.new }
  let(:null_class) { 
    Naught.build do |b|
      b.black_hole
    end
  }

  it 'returns self from arbitray method calls' do
    expect(null.info).to be(null)
    expect(null.foobar).to be(null)
    expect(null << "baz").to be(null)
  end
end

describe 'null object mimicking a class' do
  class User
    def login
      "bob"
    end
  end

  module Authorizable
    def authorized_for?(object)
      true
    end
  end

  class LibraryPatron < User
    include Authorizable

    def member?; true; end
    def name; "Bob"; end
    def notify_of_overdue_books(titles)
      puts "Notifying Bob his books are overdue..."
    end
  end

  subject(:null) { mimic_class.new }
  let(:mimic_class) { 
    Naught.build do |b|
      b.mimic LibraryPatron
    end
  }

  it 'responds to all methods defined on the target class' do
    expect(null.member?).to be_nil
    expect(null.name).to be_nil
    expect(null.notify_of_overdue_books).to be_nil
  end

  it 'does not respond to methods not defined on the target class' do
    expect{null.foobar}.to raise_error(NoMethodError)
  end

  it 'reports which messages it does and does not respond to' do
    expect(null).to respond_to(:member?)
    expect(null).to respond_to(:name)
    expect(null).to respond_to(:notify_of_overdue_books)
    
    expect(null).to_not respond_to(:foobar)
  end

  it 'has an informative inspect string' do
    expect(null.inspect).to eq("<null:Naught::LibraryPatron>")
  end


  it 'excludes Object methods from being mimicked' do
    expect(null.object_id).not_to be_nil
    expect(null.hash).not_to be_nil
  end

  it 'includes inherited methods' do
    expect(null.authorized_for?('something')).to be_nil
    expect(null.login).to be_nil
  end

  describe 'with include_super: false' do
    let(:mimic_class) { 
      Naught.build do |b|
        b.mimic LibraryPatron, include_super: false
      end
    }

    it 'excludes inherited methods' do
      expect(null).to_not respond_to(:authorized_for?)
      expect(null).to_not respond_to(:login)
    end
  end
end

describe 'using mimic with black_hole' do
  require 'logger'
  subject(:null) { mimic_class.new }
  let(:mimic_class) {
    Naught.build do |b|
      b.mimic Logger
      b.black_hole
    end
  }

  def self.it_behaves_like_a_black_hole_mimic
    it 'returns self from mimicked methods' do
      expect(null.info).to equal(null)
      expect(null.error).to equal(null)
      expect(null << "test").to equal(null)
    end

    it 'does not respond to methods not defined on the target class' do
      expect{null.foobar}.to raise_error(NoMethodError)
    end
  end

  it_behaves_like_a_black_hole_mimic

  describe '(reverse order)' do
    let(:mimic_class) {
      Naught.build do |b|
        b.black_hole
        b.mimic Logger
      end
    }

    it_behaves_like_a_black_hole_mimic
  end
end

describe 'null object impersonating another type' do
  class Point
    def x; 23; end
    def y; 42; end
  end

  subject(:null) { impersonation_class.new }
  let(:impersonation_class) {
    Naught.build do |b|
      b.impersonate Point
    end
  }

  it 'matches the impersonated type' do
    expect(Point).to be === null
  end

  it 'responds to methods from the impersonated type' do
    expect(null.x).to be_nil
    expect(null.y).to be_nil
  end

  it 'dose not respond to unknown methods' do
    expect{null.foobar}.to raise_error(NoMethodError)
  end
end

describe 'traceable null object' do
  subject(:trace_null) {
    null_object_and_line.first
  }
  let(:null_object_and_line) {
    obj = trace_null_class.new; line = __LINE__;
    [obj, line]
  }
  let(:instantiation_line) { null_object_and_line.last }
  let(:trace_null_class) {
    Naught.build do |b|
      b.traceable
    end
  }

  it 'remembers the file it was instantiated from' do
    expect(trace_null.__file__).to eq(__FILE__)    
  end

  it 'remembers the line it was instantiated from' do
    expect(trace_null.__line__).to eq(instantiation_line)
  end

  def make_null
    trace_null_class.new(caller: Kernel.caller_locations(1))
  end

  it 'can accept custom backtrace info' do
    obj = make_null; line = __LINE__
    expect(obj.__line__).to eq(line)
  end
end

describe 'customized null object' do
  subject(:custom_null) { custom_null_class.new }
  let(:custom_null_class) {
    Naught.build do |b|
      b.define_explicit_conversions

      def to_path
        "/dev/null"
      end

      def to_s
        "NOTHING TO SEE HERE"
      end
    end
  }

  it 'responds to custom-defined methods' do
    expect(custom_null.to_path).to eql("/dev/null")
  end

  it 'allows  generated methods to be overriden' do
    expect(custom_null.to_s).to eql("NOTHING TO SEE HERE")
  end
end

describe 'a named null object class' do
  TestNull = Naught.build

  it 'has named ancestor modules' do
    expect(TestNull.ancestors.map(&:name)).to eq([
        'TestNull::Customizations', 
        'TestNull',
        'BasicObject'
      ])
  end
end

ConvertableNull = Naught.build do |b|
  b.null_equivalents << ""
  b.traceable
end

describe 'Null()' do
  include ConvertableNull::Conversions

  specify 'given no input, returns a null object' do
    expect(Null().class).to be(ConvertableNull)
  end

  specify 'given nil, returns a null object' do
    expect(Null(nil).class).to be(ConvertableNull)
  end

  specify 'given a null object, returns the same null object' do
    null = ConvertableNull.new
    expect(Null(null)).to be(null)
  end

  specify 'given anything in null_equivalents, return a null object' do
    expect(Null("").class).to be(ConvertableNull)
  end

  specify 'given anything else, raises an ArgumentError' do
    expect{Null(false)}.to raise_error(ArgumentError)
    expect{Null("hello")}.to raise_error(ArgumentError)
  end

  it 'generates null objects with useful trace info' do
    null = Null(); line = __LINE__
    expect(null.__line__).to eq(line)
    expect(null.__file__).to eq(__FILE__)
  end
end

describe 'Maybe()' do
  include ConvertableNull::Conversions

  specify 'given nil, returns a null object' do
    expect(Maybe(nil).class).to be(ConvertableNull)
  end

  specify 'given a null object, returns the same null object' do
    null = ConvertableNull.new
    expect(Maybe(null)).to be(null)
  end

  specify 'given anything in null_equivalents, return a null object' do
    expect(Maybe("").class).to be(ConvertableNull)
  end

  specify 'given anything else, returns the input unchanged' do
    expect(Maybe(false)).to be(false)
    str = "hello"
    expect(Maybe(str)).to be(str)
  end

  it 'generates null objects with useful trace info' do
    null = Maybe(); line = __LINE__
    expect(null.__line__).to eq(line)
    expect(null.__file__).to eq(__FILE__)
  end  

  it 'also works with blocks' do
    expect(Maybe{nil}.class).to eq(ConvertableNull)
    expect(Maybe{"foo"}).to eq("foo")
  end
end

describe 'Just()' do
  include ConvertableNull::Conversions

  specify 'passes non-nullish values through' do
    expect(Just(false)).to be(false)
    str = "hello"
    expect(Just(str)).to be(str)
  end

  specify 'rejects nullish values' do
    expect{Just(nil)}.to raise_error(ArgumentError)
    expect{Just("")}.to raise_error(ArgumentError)
    expect{Just(ConvertableNull.new)}.to raise_error(ArgumentError)
  end

  it 'also works with blocks' do
    expect{Just{nil}.class}.to raise_error(ArgumentError)
    expect(Just{"foo"}).to eq("foo")
  end
end

describe 'Actual()' do
  include ConvertableNull::Conversions

  specify 'given a null object, returns nil' do
    null = ConvertableNull.new
    expect(Actual(null)).to be_nil
  end

  specify 'given anything else, returns the input unchanged' do
    expect(Actual(false)).to be(false)
    str = "hello"
    expect(Actual(str)).to be(str)
    expect(Actual(nil)).to be_nil
  end

  it 'also works with blocks' do
    expect(Actual{ConvertableNull.new}).to be_nil
    expect(Actual{"foo"}).to eq("foo")
  end
end
