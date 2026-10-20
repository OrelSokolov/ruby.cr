# Ruby::V4::Rational — минимальный Rational (num/den на Int64) для Time#subsec
# и разности дат. Инспект "(n/d)" как в Ruby: (1/2), (0/1).

module Ruby
  module V4
    struct Rational
      getter num : Int64
      getter den : Int64

      def initialize(@num : Int64, @den : Int64)
        if @num == 0
          @den = 1_i64
        else
          g = @num.abs.gcd(@den)
          @num //= g
          @den //= g
        end
      end

      def self.from_ratio(num : Int, den : Int) : self
        new(num.to_i64, den.to_i64)
      end

      # Точное значение Float64 как рациональная дробь (по битам IEEE754):
      # 0.5 → (1/2), 0.123456789 → (8895999182988127/72057594037927936).
      def self.from_float(f : Float64) : self
        return new(0_i64, 1_i64) if f == 0.0
        bits = f.unsafe_as(UInt64)
        neg = (bits >> 63) == 1
        exp = ((bits >> 52) & 0x7ff_u64).to_i32
        mant = (bits & 0xf_ffff_ffff_ffff_u64).to_i64
        if exp == 0
          num = mant
          shift = 1074
        else
          num = mant | (1_i64 << 52)
          shift = 1075 - exp
        end
        # Дробная часть всегда < 1; для сверхмалых экспонент знаменатель
        # не помещается в Int64 — теряем точность (за пределами практики).
        if shift > 62
          k = shift - 62
          num >>= k
          shift = 62
        end
        r = new(num, 1_i64 << shift)
        neg ? new(-r.num, r.den) : r
      end

      def zero? : Bool
        @num == 0
      end

      def to_f : Float64
        @num.to_f64 / @den.to_f64
      end

      def inspect : String
        "(#{@num}/#{@den})"
      end

      def to_s : String
        inspect
      end
    end
  end
end
