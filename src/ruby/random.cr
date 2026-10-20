# Ruby::V4::Random — генератор с MT19937 и семантикой rand из Ruby:
# rand / rand(int) / rand(range) / rand(float) / bytes / srand+глобальный rand.
# Массивы: Array#shuffle(random: Ruby::V4::Random.new(seed)) даёт порядок Ruby.

module Ruby
  module V4
    class Random
      @mt : MT19937

      def initialize(seed : Int)
        @mt = MT19937.new
        @mt.seed(seed)
      end

      # Целое в [0, limit] включительно (limited_rand из random.c Ruby).
      def limited(limit : UInt64) : UInt64
        if limit < 0x1_0000_0000_u64
          lim = limit.to_u32!
          return 0_u64 if lim == 0
          mask = 0_u32
          while mask < lim && mask < 0xffffffff_u32
            mask = (mask << 1) | 1
          end
          loop do
            val = @mt.next_u32 & mask
            return val.to_u64 if val <= lim
          end
        else
          mask = 0_u64
          while mask < limit
            mask = (mask << 1) | 1
          end
          loop do
            val = ((@mt.next_u32.to_u64 << 32) | @mt.next_u32.to_u64) & mask
            return val if val <= limit
          end
        end
      end

      # Целое в [0, max) — rand(int) в Ruby.
      def rand(max : Int) : Int64
        raise ArgumentError.new("invalid argument") if max <= 0
        limited(max.to_u64 &- 1).to_i64
      end

      # rand(range): целые диапазоны включительно/исключительно.
      def rand(range : Range(Int, Int))
        min = range.begin.not_nil!
        max = range.end.not_nil!
        span = range.exclusive? ? max - min - 1 : max - min
        raise ArgumentError.new("invalid argument") if span < 0
        limited(span.to_u64).to_i64 + min.to_i64
      end

      # rand(float..float) / rand(int..float): как rand_range в random.c —
      # random_real(excl) * (end-begin) + begin. Для inclusive-диапазона
      # используется int_pair_to_real_inclusive из двух слов MT.
      def rand(range : Range(Float, Float)) : Float64
        min = range.begin.not_nil!.to_f64
        max = range.end.not_nil!.to_f64
        raise ArgumentError.new("invalid argument") if max < min
        r = range.exclusive? ? genrand_float : genrand_float_inclusive
        r * (max - min) + min
      end

      def rand(range : Range(Int, Float)) : Float64
        min = range.begin.not_nil!.to_f64
        max = range.end.not_nil!.to_f64
        raise ArgumentError.new("invalid argument") if max < min
        r = range.exclusive? ? genrand_float : genrand_float_inclusive
        r * (max - min) + min
      end

      # rand(max : Float) — random_float * max.
      def rand(max : Float) : Float64
        raise ArgumentError.new("invalid argument") if max <= 0
        genrand_float * max
      end

      def rand : Float64
        genrand_float
      end

      private def genrand_float : Float64
        a = @mt.next_u32 >> 5
        b = @mt.next_u32 >> 6
        (a.to_f64 * 67108864.0 + b.to_f64) / 9007199254740992.0
      end

      # int_pair_to_real_inclusive из random.c: [0,1] включительно.
      private def genrand_float_inclusive : Float64
        a = @mt.next_u32
        b = @mt.next_u32
        x = ((a.to_u64 << 21) + ((b.to_u64 + (a >> 21)) >> 11))
        x.to_f64 * (1.0 / 9007199254740992.0)
      end

      # Случайные байты: слова genrand little-endian, хвост — младшие байты.
      def bytes(n : Int) : Array(UInt8)
        out = Array(UInt8).new(n, 0_u8)
        i = 0
        while i + 4 <= n
          x = @mt.next_u32
          out[i] = (x & 0xff).to_u8
          out[i + 1] = ((x >> 8) & 0xff).to_u8
          out[i + 2] = ((x >> 16) & 0xff).to_u8
          out[i + 3] = (x >> 24).to_u8
          i += 4
        end
        if i < n
          x = @mt.next_u32
          while i < n
            out[i] = (x & 0xff).to_u8
            x >>= 8
            i += 1
          end
        end
        out
      end

      # --- глобальный генератор (srand/rand Kernel) ---
      @@global = Random.new(0)

      def self.srand(seed : Int) : Int
        @@global = Random.new(seed)
        seed
      end

      def self.rand : Float64
        @@global.rand
      end

      def self.rand(max) : Int64 | Float64
        @@global.rand(max)
      end

      def self.global : Random
        @@global
      end
    end
  end
end
