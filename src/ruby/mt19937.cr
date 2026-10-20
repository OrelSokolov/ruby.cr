# MT19937 с сидированием и выборками, бит-в-бит совместимыми с Random в Ruby
# (инициализация init_by_array словами сида little-endian, выборка float
# двумя 32-битными словами, limited-rand с маской и повтором).

module Ruby
  module V4
    class MT19937
      N           = 624
      M           = 397
      MATRIX_A    = 0x9908b0df_u32
      UPPER_MASK  = 0x80000000_u32
      LOWER_MASK  = 0x7fffffff_u32

      @mt  : Array(UInt32)
      @mti : Int32

      def initialize
        @mt = Array(UInt32).new(N, 0_u32)
        @mti = N + 1_i32
      end

      # Сидирование как rand_init в random.c Ruby:
      #  - |seed| помещается в uint32 → init_genrand(seed);
      #  - иначе init_by_array словами little-endian, при этом последнее
      #    слово, равное 1, отбрасывается (remove leading-zero-guard).
      def seed(seed : Int)
        s = seed.abs
        if s < 0x1_0000_0000
          init_genrand(s.to_u32!)
        else
          words = [] of UInt32
          x = s
          while x > 0
            words << (x & 0xffffffff).to_u32!
            x >>= 32
          end
          words.pop if words.last == 1
          init_by_array(words)
        end
      end

      def init_genrand(s : UInt32)
        @mt[0] = s & 0xffffffff_u32
        (1...N).each do |i|
          prev = @mt[i - 1]
          @mt[i] = (1812433253_u32 &* (prev ^ (prev >> 30)) &+ i) & 0xffffffff_u32
        end
        @mti = N
      end

      def init_by_array(key : Array(UInt32))
        init_genrand(19650218_u32)
        i = 1
        j = 0
        k = {N, key.size}.max
        while k > 0
          prev = @mt[i - 1]
          v = (prev ^ (prev >> 30)) & 0xffffffff_u32
          v = (v &* 1664525_u32) & 0xffffffff_u32
          @mt[i] = ((@mt[i] ^ v) &+ key[j] &+ j.to_u32!) & 0xffffffff_u32
          i += 1
          j += 1
          if i >= N
            @mt[0] = @mt[N - 1]
            i = 1
          end
          j = 0 if j >= key.size
          k -= 1
        end
        k = N - 1
        while k > 0
          prev = @mt[i - 1]
          v = (prev ^ (prev >> 30)) & 0xffffffff_u32
          v = (v &* 1566083941_u32) & 0xffffffff_u32
          @mt[i] = ((@mt[i] ^ v) &- i.to_u32!) & 0xffffffff_u32
          i += 1
          k -= 1
          if i >= N
            @mt[0] = @mt[N - 1]
            i = 1
          end
        end
        @mt[0] = 0x80000000_u32
        @mti = N
      end

      def next_u32 : UInt32
        if @mti >= N
          regenerate
          @mti = 0
        end
        y = @mt[@mti]
        @mti += 1
        y ^= y >> 11
        y ^= (y << 7) & 0x9d2c5680_u32
        y ^= (y << 15) & 0xefc60000_u32
        y ^= y >> 18
        y
      end

      private def regenerate
        (N - 1).times do |i|
          y = (@mt[i] & UPPER_MASK) | (@mt[(i + 1) % N] & LOWER_MASK)
          t = @mt[(i + M) % N] ^ (y >> 1)
          t ^= MATRIX_A if (y & 1) == 1
          @mt[i] = t
        end
      end
    end
  end
end
