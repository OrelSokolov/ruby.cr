# Ruby::V4::SecureRandom — hex/base64/urlsafe_base64/random_bytes/
# random_number/alphanumeric поверх Crystal Random::Secure.

module Ruby
  module V4
    module SecureRandom
      extend self

      ALNUM = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

      def random_bytes(n : Int = 16) : String
        slice = Bytes.new(n)
        ::Random::Secure.random_bytes(slice)
        String.new(slice)
      end

      def hex(n : Int = 16) : String
        random_bytes(n).to_slice.hexstring
      end

      def base64(n : Int = 16) : String
        Ruby::V4::Base64.strict_encode64(random_bytes(n))
      end

      def urlsafe_base64(n : Int = 16, padding : Bool = false) : String
        Ruby::V4::Base64.urlsafe_encode64(random_bytes(n), padding)
      end

      def alphanumeric(n : Int = 27) : String
        chars = [] of Char
        n.times { chars << ALNUM[::Random::Secure.rand(ALNUM.size)] }
        chars.join
      end

      def random_number(max : Int) : Int64
        ::Random::Secure.rand(max).to_i64
      end

      def random_number(max : Float) : Float64
        ::Random::Secure.rand * max
      end

      def random_number : Float64
        ::Random::Secure.rand
      end
    end
  end
end
