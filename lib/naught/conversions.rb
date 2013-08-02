module Naught
  module ExplicitConversions
    def to_s; '' end
    def to_a; [] end
    def to_i; 0 end
    def to_f; 0.0 end
    def to_c; Kernel.Complex(0) end
    def to_r; Kernel.Rational(0) end
    def to_h; {} end
  end

  module ImplicitConversions
    def to_ary; [] end
    def to_str; '' end
  end
end
