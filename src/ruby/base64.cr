# Ruby::V4::Base64 — encode64/strict_encode64/decode64/strict_decode64/
# urlsafe_encode64/urlsafe_decode64 с семантикой Ruby:
# encode64 переносит строки каждые 60 символов + "\n"; urlsafe без "=".

module Ruby
  module V4
    module Base64
      extend self

      STD_ALPHA    = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
      URL_ALPHA    = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
      REVERSE_STD  = STD_ALPHA.chars.each_with_index.to_h { |c, i| {c, i} }
      REVERSE_URL  = URL_ALPHA.chars.each_with_index.to_h { |c, i| {c, i} }

      private def encode_bytes(bytes : Bytes, alphabet : String, padding : Bool) : String
        buf = String::Builder.new
        i = 0
        n = bytes.size
        while i + 2 < n
          v = (bytes[i].to_u32 << 16) | (bytes[i + 1].to_u32 << 8) | bytes[i + 2].to_u32
          buf << alphabet[(v >> 18) & 63] << alphabet[(v >> 12) & 63] << alphabet[(v >> 6) & 63] << alphabet[v & 63]
          i += 3
        end
        rem = n - i
        case rem
        when 1
          v = bytes[i].to_u32 << 16
          buf << alphabet[(v >> 18) & 63] << alphabet[(v >> 12) & 63]
          buf << "==" if padding
        when 2
          v = (bytes[i].to_u32 << 16) | (bytes[i + 1].to_u32 << 8)
          buf << alphabet[(v >> 18) & 63] << alphabet[(v >> 12) & 63] << alphabet[(v >> 6) & 63]
          buf << "=" if padding
        end
        buf.to_s
      end

      # strict: без переносов, с паддингом.
      def strict_encode64(s : String) : String
        encode_bytes(s.to_slice, STD_ALPHA, padding: true)
      end

      # encode64: строки по 60 символов, каждая с "\n" на конце.
      def encode64(s : String) : String
        strict = strict_encode64(s)
        return "" if strict.empty?
        buf = String::Builder.new
        strict.scan(/.{1,60}/m).each { |m| buf << m[0] << '\n' }
        buf.to_s
      end

      def urlsafe_encode64(s : String, padding : Bool = false) : String
        encode_bytes(s.to_slice, URL_ALPHA, padding)
      end

      # decode64: снисходительный — игнорирует пробелы/переносы.
      def decode64(s : String) : String
        decode_strict_chars(s, REVERSE_STD, strict: false)
      end

      def strict_decode64(s : String) : String
        decode_strict_chars(s, REVERSE_STD, strict: true)
      end

      def urlsafe_decode64(s : String) : String
        decode_strict_chars(s, REVERSE_URL, strict: true)
      end

      private def decode_strict_chars(s : String, reverse : Hash(Char, Int32), strict : Bool) : String
        vals = [] of Int32
        pad = 0
        s.each_char do |c|
          case
          when c == '='
            pad += 1
          when reverse[c]?
            vals << reverse[c]
          when c.ascii_whitespace?
            raise ArgumentError.new("invalid base64 (strict)") if strict
          else
            raise ArgumentError.new("invalid base64: #{c.inspect}") if strict
          end
        end
        buf = IO::Memory.new
        i = 0
        n = vals.size
        while i + 3 < n
          v = (vals[i] << 18) | (vals[i + 1] << 12) | (vals[i + 2] << 6) | vals[i + 3]
          buf.write_byte(((v >> 16) & 0xff).to_u8!)
          buf.write_byte(((v >> 8) & 0xff).to_u8!)
          buf.write_byte((v & 0xff).to_u8!)
          i += 4
        end
        rem = n - i
        if rem == 3
          v = (vals[i] << 18) | (vals[i + 1] << 12) | (vals[i + 2] << 6)
          buf.write_byte(((v >> 16) & 0xff).to_u8!)
          buf.write_byte(((v >> 8) & 0xff).to_u8!)
        elsif rem == 2
          v = (vals[i] << 18) | (vals[i + 1] << 12)
          buf.write_byte(((v >> 16) & 0xff).to_u8!)
        end
        String.new(buf.to_slice)
      end
    end
  end
end
