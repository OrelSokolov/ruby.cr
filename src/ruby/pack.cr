# Ruby::V4 pack/unpack — Array#pack(fmt) и String#unpack(fmt)/unpack1(fmt).
# Поддержаны директивы: C c S s L l Q q J P (модификаторы < >), v V n N,
# e E f d g G, U (UTF-8), w (BER), m/m0 (base64), H h (hex), a A Z (строки),
# B b (биты), M (quoted-printable), u (uuencode), x X @.
# Повторитель: * или число; несколько директив подряд ("A2A3").

module Ruby
  module V4
    alias PackValue = Int64 | Float64 | String

    module Pack
      extend self

      private class Cursor
        property pos : Int32 = 0
        property item : Int32 = 0

        def initialize(@items : Array, @bytes : Bytes)
        end

        def next_item
          v = @items[@item]?
          @item += 1
          v
        end

        def byte : UInt8?
          @bytes[@pos]?.tap { |b| @pos += 1 if b }
        end

        def remaining : Int32
          @bytes.size - @pos
        end
      end

      def pack(items : Array, fmt : String) : String
        io = IO::Memory.new
        item = 0
        i = 0
        n = fmt.size
        while i < n
          dir = fmt[i]
          i += 1
          # endianness-модификаторы
          endian = :native
          if i < n && (fmt[i] == '<' || fmt[i] == '>')
            endian = fmt[i] == '<' ? :little : :big
            i += 1
          elsif i < n && (fmt[i] == '!' || fmt[i] == '_')
            i += 1
          end
          # повторитель
          count = 1
          star = false
          if i < n && fmt[i] == '*'
            star = true
            i += 1
          elsif i < n && fmt[i].ascii_number?
            start = i
            while i < n && fmt[i].ascii_number?
              i += 1
            end
            count = fmt[start...i].to_i
          end
          count = items.size - item if star
          # B/b: * — вся строка битов (count тут считается по элементам).
          count = Int32::MAX if star && (dir == 'B' || dir == 'b')

          pack_directive(io, items, pointerof(item), dir, count, endian)
        end
        String.new(io.to_slice)
      end

      private def pack_directive(io, items, item, dir : Char, count : Int32, endian) : Nil
        little = endian != :big # native на x86_64 — LE
        case dir
        when 'C', 'c'
          count.times do
            v = items[item.value]? || break
            io.write_byte(int_item(v).to_u8!)
            item.value += 1
          end
        when 'S', 'v', 'n', 's'
          count.times do
            v = items[item.value]? || break
            u = int_item(v).to_u16!
            le = dir == 'n' ? false : (dir == 'v' ? true : little)
            write_u16(io, u, le)
            item.value += 1
          end
        when 'L', 'l', 'V', 'N'
          count.times do
            v = items[item.value]? || break
            u = int_item(v).to_u32!
            le = dir == 'N' ? false : (dir == 'V' ? true : little)
            write_u32(io, u, le)
            item.value += 1
          end
        when 'Q', 'q', 'J', 'P'
          count.times do
            v = items[item.value]? || break
            u = int_item(v).to_u64!
            write_u64(io, u, little)
            item.value += 1
          end
        when 'e', 'f'
          count.times do
            v = items[item.value]? || break
            write_f32(io, num_item(v).to_f32, dir == 'e' || little)
            item.value += 1
          end
        when 'E', 'd', 'G', 'g'
          count.times do
            v = items[item.value]? || break
            write_f64(io, num_item(v).to_f64, dir == 'G' ? false : (dir == 'E' || little))
            item.value += 1
          end
        when 'U'
          count.times do
            v = items[item.value]? || break
            io << (int_item(v).to_u32.chr rescue '?')
            item.value += 1
          end
        when 'w'
          count.times do
            v = items[item.value]? || break
            write_ber(io, int_item(v))
            item.value += 1
          end
        when 'm'
          strict = Base64.strict_encode64(str_item(items, item))
          # m0 — строго без переносов; m — строки по 60 символов + "\n".
          if count == 0
            io << strict
          else
            strict.scan(/.{1,60}/m).each { |l| io << l[0] << '\n' }
          end
        when 'H', 'h'
          s = str_item(items, item)
          out = String::Builder.new
          high = dir == 'H'
          k = 0
          while k < s.size
            hi = s[k].to_i?(16)
            lo = s[k + 1]?.try &.to_i?(16) || 0
            if hi.nil?
              hi = 0
            end
            out << ((high ? hi * 16 + lo : lo * 16 + hi)).to_u8.chr
            k += 2
          end
          io << out.to_s
        when 'a', 'A', 'Z'
          v = items[item.value]? || ""
          s = v.to_s
          item.value += 1
          pad = dir == 'A' ? ' ' : '\0'
          if count > s.size
            io << s << (pad.to_s * (count - s.size))
          else
            io << s[0, count]
          end
        when 'B', 'b'
          s = str_item(items, item)
          bits = count.zero? ? s : s[0, count]
          nbytes = (bits.size + 7) // 8
          msb = dir == 'B'
          nbytes.times do |bi|
            byte = 0_u8
            8.times do |k|
              bit = bits[bi * 8 + k]?
              next unless bit == '1'
              byte |= (msb ? 0x80_u8 >> k : 1_u8 << k)
            end
            io.write_byte(byte)
          end
        when 'M'
          # Quoted-printable (бит-в-бит с ruby pack.c qpencode): =XX для
          # непечатных/'='/DEL, '\n' и '\t' — сырыми ('\n' сбрасывает счётчик
          # строки), мягкий перенос "=\n" после 73-го символа строки,
          # в конце всегда "=\n".
          s = str_item(items, item)
          lineno = 0
          s.each_byte do |b|
            if b == '\n'.ord
              io.write_byte(b)
              lineno = 0
            elsif b > 126 || (b < 32 && b != '\t'.ord) || b == '='.ord
              io << '=' << b.to_s(16).upcase.rjust(2, '0')
              lineno += 3
              if lineno > 72
                io << "=\n"
                lineno = 0
              end
            else
              io.write_byte(b)
              lineno += 1
              if lineno > 72
                io << "=\n"
                lineno = 0
              end
            end
          end
          io << "=\n"
        when 'u'
          s = str_item(items, item)
          i = 0
          while i < s.bytesize
            chunk = s.bytesize - i
            chunk = 45 if chunk > 45
            io.write_byte((chunk + 32).to_u8!)
            k = 0
            while k < chunk
              b0 = s.to_unsafe[i + k].to_u32
              b1 = k + 1 < chunk ? s.to_unsafe[i + k + 1].to_u32 : 0
              b2 = k + 2 < chunk ? s.to_unsafe[i + k + 2].to_u32 : 0
              v = (b0 << 16) | (b1 << 8) | b2
              4.times do |e|
                six = (v >> (18 - 6 * e)) & 0x3f
                io.write_byte(six == 0 ? '`'.ord.to_u8 : (six + 32).to_u8!)
              end
              k += 3
            end
            io << '\n'
            i += chunk
          end
        when 'x'
          count.times { io.write_byte(0_u8) }
        when 'X'
          io.pos = io.pos - count
        when '@'
          while io.pos < count
            io.write_byte(0_u8)
          end
          io.pos = count
        else
          raise ArgumentError.new("pack: неподдерживаемая директива #{dir.inspect}")
        end
      end

      private def str_item(items, item) : String
        v = items[item.value]? || ""
        item.value += 1
        v.to_s
      end

      private def int_item(v) : Int64
        i = v.as?(Int)
        raise ArgumentError.new("pack: expected Integer, got #{v.class}") unless i
        i.to_i64
      end

      private def num_item(v) : Number
        i = v.as?(Number)
        raise ArgumentError.new("pack: expected Number, got #{v.class}") unless i
        i
      end

      private def write_u16(io, v : UInt16, le : Bool)
        if le
          2.times { |k| io.write_byte((v >> (8 * k)).to_u8!) }
        else
          2.times { |k| io.write_byte((v >> (8 * (1 - k))).to_u8!) }
        end
      end

      private def write_u32(io, v : UInt32, le : Bool)
        if le
          4.times { |k| io.write_byte((v >> (8 * k)).to_u8!) }
        else
          4.times { |k| io.write_byte((v >> (8 * (3 - k))).to_u8!) }
        end
      end

      private def write_u64(io, v : UInt64, le : Bool)
        if le
          8.times { |k| io.write_byte((v >> (8 * k)).to_u8!) }
        else
          8.times { |k| io.write_byte((v >> (8 * (7 - k))).to_u8!) }
        end
      end

      private def write_f32(io, v : Float32, le : Bool)
        write_u32(io, v.unsafe_as(UInt32), le)
      end

      private def write_f64(io, v : Float64, le : Bool)
        write_u64(io, v.unsafe_as(UInt64), le)
      end

      private def write_ber(io, v : Int) : Nil
        bytes = [] of UInt8
        n = v.to_u64
        loop do
          bytes << (n & 0x7f).to_u8!
          break if n < 0x80
          n >>= 7
        end
        bytes.reverse.each_with_index do |b, ri|
          io.write_byte(ri == bytes.size - 1 ? b : (b | 0x80_u8))
        end
      end

      # --- unpack ---

      def unpack(s : String, fmt : String) : Array(PackValue)
        bytes = s.to_slice
        pos = 0
        out = [] of PackValue
        i = 0
        n = fmt.size
        while i < n
          dir = fmt[i]
          i += 1
          endian = :native
          if i < n && (fmt[i] == '<' || fmt[i] == '>')
            endian = fmt[i] == '<' ? :little : :big
            i += 1
          elsif i < n && (fmt[i] == '!' || fmt[i] == '_')
            i += 1
          end
          count = 1
          star = false
          if i < n && fmt[i] == '*'
            star = true
            i += 1
          elsif i < n && fmt[i].ascii_number?
            start = i
            while i < n && fmt[i].ascii_number?
              i += 1
            end
            count = fmt[start...i].to_i
          end
          count = bytes.size - pos if star
          count = 0 if count < 0
          # H/h: счётчик — число hex-СИМВОЛОВ (по 2 на байт).
          count *= 2 if star && (dir == 'H' || dir == 'h')

          case dir
          when 'C', 'c'
            count.times do
              b = byte_at(bytes, pointerof(pos))
              break unless b
              out << (dir == 'C' ? b.to_i64 : b.to_i8!.to_i64)
            end
          when 'S', 'v', 'n', 's'
            count.times do
              le = dir == 'n' ? false : (dir == 'v' ? true : endian != :big)
              v = read_u16(bytes, pointerof(pos), le)
              break unless v
              out << (dir == 's' ? v.to_i16!.to_i64 : v.to_i64)
            end
          when 'L', 'l', 'V', 'N'
            count.times do
              le = dir == 'N' ? false : (dir == 'V' ? true : endian != :big)
              v = read_u32(bytes, pointerof(pos), le)
              break unless v
              out << (dir == 'l' ? v.to_i32!.to_i64 : v.to_i64)
            end
          when 'Q', 'q', 'J', 'P'
            count.times do
              v = read_u64(bytes, pointerof(pos), endian != :big)
              break unless v
              out << v.to_i64! # битовая интерпретация (отрицательные q)
            end
          when 'e', 'f'
            count.times do
              v = read_u32(bytes, pointerof(pos), dir == 'e' || endian != :big)
              break unless v
              out << v.unsafe_as(Float32).to_f64
            end
          when 'E', 'd', 'G', 'g'
            count.times do
              v = read_u64(bytes, pointerof(pos), dir == 'G' ? false : (dir == 'E' || endian != :big))
              break unless v
              out << v.unsafe_as(Float64)
            end
          when 'U'
            while count > 0 && pos < bytes.size
              reader = Char::Reader.new(s, pos)
              ch = reader.current_char
              reader.next_char
              out << ch.ord.to_i64
              pos = reader.pos
              count -= 1
            end
          when 'w'
            count.times do
              v = read_ber(bytes, pointerof(pos))
              break unless v
              out << v
            end
          when 'm'
            data = s[pos..]
            pos = bytes.size
            out << Base64.decode64(data)
          when 'M'
            # Quoted-printable decode: =XX (hex, регистронезависимо),
            # "=\n" — мягкий перенос (пропускается), одиночный '=' без
            # продолжения — литерал.
            buf = IO::Memory.new
            stop = bytes.size
            while pos < stop
              b = bytes[pos]
              if b == '='.ord
                c1 = bytes[pos + 1]?
                c2 = bytes[pos + 2]?
                if c1 == '\n'.ord
                  pos += 2
                elsif c1 && c2 && (h1 = c1.unsafe_chr.to_i?(16)) && (h2 = c2.unsafe_chr.to_i?(16))
                  buf.write_byte((h1 * 16 + h2).to_u8)
                  pos += 3
                else
                  buf.write_byte(b)
                  pos += 1
                end
              else
                buf.write_byte(b)
                pos += 1
              end
            end
            out << String.new(buf.to_slice)
          when 'u'
            # uudecode: первый символ строки — длина ((c − 32) & 63;
            # '`' и пробел кодируют 0), далее группы по 4 символа → 3 байта.
            buf = IO::Memory.new
            while pos < bytes.size
              lend = pos
              while lend < bytes.size && bytes[lend] != '\n'.ord
                lend += 1
              end
              remaining = ((bytes[pos] &- 32) & 63)
              d = pos + 1
              while remaining > 0 && d < lend
                c1 = ((bytes[d] &- 32) & 63).to_u32
                c2 = d + 1 < lend ? ((bytes[d + 1] &- 32) & 63).to_u32 : 0_u32
                c3 = d + 2 < lend ? ((bytes[d + 2] &- 32) & 63).to_u32 : 0_u32
                c4 = d + 3 < lend ? ((bytes[d + 3] &- 32) & 63).to_u32 : 0_u32
                v = (c1 << 18) | (c2 << 12) | (c3 << 6) | c4
                {v >> 16, v >> 8, v}.each do |byte|
                  break if remaining == 0
                  buf.write_byte(byte.to_u8!)
                  remaining -= 1
                end
                d += 4
              end
              pos = lend < bytes.size ? lend + 1 : lend
            end
            out << String.new(buf.to_slice)
          when 'H', 'h'
            out << unpack_hex(bytes, pointerof(pos), count, dir == 'H')
          when 'a', 'A'
            avail = bytes.size - pos
            take = count.zero? || count > avail ? avail : count
            chunk = String.new(bytes[pos, take])
            pos += take
            out << (dir == 'A' ? chunk.rstrip(' ') : chunk.rstrip('\0'))
          when 'Z'
            # До первого NUL; при * хвост строки отбрасывается (как в Ruby).
            limit = count.zero? ? bytes.size : {count, bytes.size}.min
            endp = pos
            while endp < bytes.size && endp - pos < limit && bytes[endp] != 0
              endp += 1
            end
            out << String.new(bytes[pos, endp - pos])
            if count.zero?
              pos = bytes.size
            else
              pos = endp < bytes.size && bytes[endp] == 0 ? endp + 1 : endp
            end
          when 'B', 'b'
            nbits = count.zero? ? (bytes.size - pos) * 8 : count
            msb = dir == 'B'
            buf = String::Builder.new
            nbits.times do |k|
              byte = bytes[pos + k // 8]? || break
              bit = msb ? (byte >> (7 - k % 8)) & 1 : (byte >> (k % 8)) & 1
              buf << (bit == 1 ? '1' : '0')
            end
            pos += (nbits + 7) // 8
            out << buf.to_s
          when 'x'
            pos += count
          when '@'
            pos = count
          when 'X'
            pos -= count
          else
            raise ArgumentError.new("unpack: неподдерживаемая директива #{dir.inspect}")
          end
        end
        out
      end

      private def byte_at(bytes, pos) : UInt8?
        b = bytes[pos.value]?
        pos.value += 1 if b
        b
      end

      private def read_u16(bytes, pos, le) : UInt16?
        return nil if pos.value + 2 > bytes.size
        v = 0_u16
        2.times do |k|
          shift = le ? 8 * k : 8 * (1 - k)
          v |= bytes[pos.value + k].to_u16 << shift
        end
        pos.value += 2
        v
      end

      private def read_u32(bytes, pos, le) : UInt32?
        return nil if pos.value + 4 > bytes.size
        v = 0_u32
        4.times do |k|
          shift = le ? 8 * k : 8 * (3 - k)
          v |= bytes[pos.value + k].to_u32 << shift
        end
        pos.value += 4
        v
      end

      private def read_u64(bytes, pos, le) : UInt64?
        return nil if pos.value + 8 > bytes.size
        v = 0_u64
        8.times do |k|
          shift = le ? 8 * k : 8 * (7 - k)
          v |= bytes[pos.value + k].to_u64 << shift
        end
        pos.value += 8
        v
      end

      private def read_ber(bytes, pos) : Int64?
        return nil if pos.value >= bytes.size
        v = 0_u64
        while pos.value < bytes.size
          b = bytes[pos.value]
          pos.value += 1
          v = (v << 7) | (b & 0x7f)
          break if b & 0x80 == 0
        end
        v.to_i64
      end

      private def unpack_hex(bytes, pos, count : Int32, high : Bool) : String
        out = String::Builder.new
        while pos.value < bytes.size && (count == 0 || out.bytesize < count)
          b = bytes[pos.value]
          pos.value += 1
          hi = (b >> 4).to_s(16)
          lo = (b & 0xf).to_s(16)
          out << (high ? hi : lo) << (high ? lo : hi)
        end
        s = out.to_s
        count > 0 ? s[0, count] : s
      end
    end
  end
end

class Array
  # Ruby Array#pack.
  def pack(fmt : String) : String
    ::Ruby::V4::Pack.pack(self, fmt)
  end
end

class String
  # Ruby String#unpack / unpack1.
  def unpack(fmt : String) : Array(::Ruby::V4::PackValue)
    ::Ruby::V4::Pack.unpack(self, fmt)
  end

  def unpack1(fmt : String) : ::Ruby::V4::PackValue?
    unpack(fmt).first?
  end
end
