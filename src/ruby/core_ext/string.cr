# Аддитивные методы String из Ruby, отсутствующие в Crystal.
# Конфликтующие (уже есть с другой семантикой: lines, scan, chomp-варианты
# и т.п.) не переопределяются — см. Ruby::V4.* хелперы и DIFFERENCES.md.

class String
  # Ruby String#hex: необязательный знак и 0x, стоп на первом нечётном.
  def hex : Int32
    s = self
    s = s[2..] if s.starts_with?("0x") || s.starts_with?("0X")
    Ruby.parse_int_prefix(s, 16, signed: true)
  end

  def oct : Int32
    s = self
    if s.starts_with?("0x") || s.starts_with?("0X")
      Ruby.parse_int_prefix(s[2..], 16, signed: true)
    elsif s.starts_with?("0b") || s.starts_with?("0B")
      Ruby.parse_int_prefix(s[2..], 2, signed: true)
    elsif s.starts_with?("0o") || s.starts_with?("0O") || s.starts_with?("0d") || s.starts_with?("0D")
      s = s[2..]
      Ruby.parse_int_prefix(s, 8, signed: true)
    else
      Ruby.parse_int_prefix(s, 8, signed: true)
    end
  end

  def ord : Int32
    raise ArgumentError.new("empty string") if empty?
    each_char.first.ord
  end

  def getbyte(index : Int) : Int32?
    b = byte_at?(index)
    b ? b.to_i32 : nil
  end

  def setbyte(index : Int, byte : Int) : Nil
    b = to_unsafe[index]
    to_unsafe[index] = byte.to_u8
  end

  def byteslice(start : Int, count : Int) : String?
    byte_slice?(start, count)
  end

  # Вариадические start_with?/end_with? (в Crystal — одиночный аргумент).
  def start_with?(*prefixes : String) : Bool
    prefixes.any? { |p| starts_with?(p) }
  end

  def start_with?(*prefixes : Char) : Bool
    prefixes.any? { |p| starts_with?(p) }
  end

  def end_with?(*suffixes : String) : Bool
    suffixes.any? { |s| ends_with?(s) }
  end

  def end_with?(*suffixes : Char) : Bool
    suffixes.any? { |s| ends_with?(s) }
  end

  # padding-строкой (в Crystal — только Char).
  def center(width : Int, pad : String) : String
    Ruby.pad_string(self, width, pad, :center)
  end

  def ljust(width : Int, pad : String) : String
    Ruby.pad_string(self, width, pad, :left)
  end

  def rjust(width : Int, pad : String) : String
    Ruby.pad_string(self, width, pad, :right)
  end
end

module Ruby
  extend self

  def parse_int_prefix(s : String, base : Int, signed : Bool) : Int32
    sign = 1
    idx = 0
    if signed && s.size > 1 && (s[0] == '-' || s[0] == '+')
      sign = -1 if s[0] == '-'
      idx = 1
    end
    val = 0_i64
    found = false
    while idx < s.size
      c = s[idx]
      digit = c.to_i?(base)
      break unless digit
      val = val * base + digit
      found = true
      idx += 1
    end
    sign * (found ? val : 0).to_i32
  end

  def pad_string(s : String, width : Int, pad : String, mode) : String
    raise ArgumentError.new("zero width padding") if pad.empty?
    return s if s.size >= width
    total = width - s.size
    case mode
    when :left
      l = total // pad.size
      r = total % pad.size
      s + pad * l + pad[0, r]
    when :right
      l = total // pad.size
      r = total % pad.size
      pad * l + pad[0, r] + s
    else
      left = total // 2
      right = total - left
      lp = pad * (left // pad.size) + pad[0, left % pad.size]
      rp = pad * (right // pad.size) + pad[0, right % pad.size]
      lp + s + rp
    end
  end
end

class String
  # swapcase нет в Crystal.
  def swapcase : String
    String.build(size) do |b|
      each_char do |c|
        if c.ascii_uppercase?
          b << c.downcase
        elsif c.ascii_lowercase?
          b << c.upcase
        else
          b << c
        end
      end
    end
  end
end

class String
  # String#slice(start, count) как в Ruby (в Crystal только byte_slice).
  def slice(start : Int, count : Int) : String
    self[start, count]
  end
end

class String
  # concat: в Ruby мутирует и возвращает self; строки Crystal неизменяемые,
  # поэтому возвращаем новую строку с тем же значением.
  def concat(other : String) : String
    self + other
  end
end

class String
  # prepend: как в Ruby (возвращаем новую строку — строки Crystal неизменяемые).
  def prepend(other : String) : String
    other + self
  end
end

class String
  def delete_prefix(prefix : String) : String
    starts_with?(prefix) ? self[prefix.size..] : self
  end

  def delete_suffix(suffix : String) : String
    ends_with?(suffix) ? self[0, size - suffix.size] : self
  end
end
