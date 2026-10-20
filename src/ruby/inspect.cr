# Ruby::V4.inspect — воспроизведение Ruby-inspect для значений Crystal:
# Tuple → Array, Char → односимвольная строка, Float с двузначной экспонентой,
# Set в формате версии (V3 "#<Set: {1, 2}>", V4 "Set[1, 2]").

module Ruby
  module V4
    extend self

    def inspect(value) : String
      case value
      when Nil             then "nil"
      when Bool            then value.to_s
      when Int             then value.to_s
      when Float           then float_to_s(value)
      when String          then string_inspect(value)
      when Char            then value.to_s.inspect
      when Symbol          then ":#{value}"
      when Array           then "[#{value.map { |v| inspect(v) }.join(", ")}]"
      when Tuple           then "[#{value.map { |v| inspect(v) }.join(", ")}]"
      when NamedTuple      then inspect_nt(value)
      when Hash            then hash_inspect(value)
      when Set             then set_inspect(value)
      when Range           then range_to_s(value)
      when ::Ruby::V4::Any
        any_inspect(value)
      when ::Ruby::V4::Time, ::Ruby::V4::Date, ::Ruby::V4::DateTime
        value.inspect
      else
        value.inspect
      end
    end

    def any_inspect(box : Any) : String
      case v = box.value
      when Array(Any) then "[#{v.map { |b| any_inspect(b) }.join(", ")}]"
      else                 inspect(v)
      end
    end

    # Ruby String#inspect: NUL → \x00 (Crystal печатает \u0000). Без NUL
    # достаточно нативного inspect, поэтому побайтовый рендер — только
    # для строк с NUL (Ruby-строки из unpack и есть binary: байты ≥ 0x80
    # в них эскейпятся побайтово, что этот рендер и даёт).
    def string_inspect(s : String) : String
      return s.inspect unless s.includes?('\0')
      out = String::Builder.new
      out << '"'
      s.each_byte do |b|
        case b
        when 0x22 then out << "\\\""
        when 0x5c then out << "\\\\"
        when 0x0a then out << "\\n"
        when 0x09 then out << "\\t"
        when 0x0d then out << "\\r"
        when 0x0c then out << "\\f"
        when 0x0b then out << "\\v"
        when 0x08 then out << "\\b"
        when 0x07 then out << "\\a"
        when 0x1b then out << "\\e"
        else
          if b < 0x20 || b >= 0x7f
            out << "\\x" << b.to_s(16).upcase.rjust(2, '0')
          else
            out << b.unsafe_chr
          end
        end
      end
      out << '"'
      out.to_s
    end

    # Float#to_s Ruby: экспонента минимум из двух цифр ("1.0e-05", не "1.0e-5").
    def float_to_s(f : Float) : String
      s = f.to_s
      if (m = s.match(/\A(.+e[+-])(\d+)\z/))
        digits = m[2]
        digits = "0#{digits}" if digits.size < 2
        "#{m[1]}#{digits}"
      else
        s
      end
    end

    def hash_inspect(h : Hash) : String
      return "{}" if h.empty?
      "{" + h.map { |k, v| "#{inspect_key(k)} => #{inspect(v)}" }.join(", ") + "}"
    end

    # Хэш с "символьными" ключами как в Ruby: {x: 1, y: 2}.
    def sym_hash_inspect(pairs : Array(Tuple(String, _))) : String
      "{#{pairs.map { |k, v| "#{k}: #{inspect(v)}" }.join(", ")}}"
    end

    # Массив "символов" как в Ruby: [:x, :y].
    def sym_array_inspect(names : Array(String)) : String
      "[#{names.map { |n| ":#{n}" }.join(", ")}]"
    end

    # Rational из разности дат: Date - Date → "2/1".
    def rational_inspect(num : Int, den : Int) : String
      "(#{num}/#{den})"
    end

    def set_inspect(s : Set) : String
      inner = s.to_a.map { |v| inspect(v) }.join(", ")
      "Set[#{inner}]"
    end

    private def inspect_key(k) : String
      inspect(k)
    end

    private def inspect_nt(nt : NamedTuple) : String
      parts = [] of String
      nt.each do |k, v|
        parts << "#{k}: #{inspect(v)}"
      end
      "{#{parts.join(", ")}}"
    end

    def range_to_s(r : Range) : String
      "#{inspect(r.begin)}#{r.exclusive? ? "..." : ".."}#{inspect(r.end)}"
    end
  end

  module V3
    extend self

    # Отличие V3 от V4 на нашей поверхности: формат Set#inspect/to_s.
    def set_inspect(s : Set) : String
      inner = s.to_a.map { |v| Ruby::V4.inspect(v) }.join(", ")
      "#<Set: {#{inner}}>"
    end

    # Set#^ в V3 кладёт сперва элементы other\self, затем self\other.
    def set_xor(a : Set(T), b : Set(T)) : Set(T) forall T
      out = Set(T).new
      b.each { |v| out << v unless a.includes?(v) }
      a.each { |v| out << v unless b.includes?(v) }
      out
    end
  end
end

# --- Ruby-совместимые хелперы для конфликтных методов (см. DIFFERENCES.md) ---

module Ruby
  module V4
    extend self

    # String#lines Ruby: разрывы сохраняются в элементах.
    def lines(s : String) : Array(String)
      out = [] of String
      cur = String::Builder.new
      s.each_char do |c|
        cur << c
        if c == '\n'
          out << cur.to_s
          cur = String::Builder.new
        end
      end
      tail = cur.to_s
      out << tail unless tail.empty?
      out
    end

    # String#scan Ruby: массив совпавших строк (не MatchData).
    def scan(s : String, re : Regex) : Array(String)
      s.scan(re).map &.[0]
    end

    # Array#zip Ruby: более короткий массив дополняется nil.
    def zip(a : Array(T), b : Array(U)) : Array(Array(T | U | Nil)) forall T, U
      n = {a.size, b.size}.max
      Array.new(n) do |i|
        [a[i]?, b[i]?]
      end
    end

    # Integer#chr Ruby: строка из одного символа (в Crystal chr → Char).
    def chr(i : Int) : String
      i.chr.to_s
    end

    # Float#round Ruby: по умолчанию half: :up; без знаков — Integer.
    def round(x : Float, digits : Int = 0, half : Symbol = :up)
      mode = case half
             when :up   then Number::RoundingMode::TIES_AWAY
             when :down then Number::RoundingMode::TO_ZERO
             else            Number::RoundingMode::TIES_EVEN
             end
      if digits == 0
        x.round(mode: mode).to_i64
      else
        factor = 10.0 ** digits
        (x * factor).round(mode: mode) / factor
      end
    end

    # Set#add? Ruby: мутирует и возвращает сет, либо nil если элемент был.
    def set_add?(s : Set(T), v : T) : Set(T)? forall T
      return nil if s.includes?(v)
      s << v
      s
    end
  end
end

module Ruby
  module V4
    extend self

    # flatten с ограничением глубины. Рекурсивные союзы типов не выражаются
    # в Crystal, поэтому элементы боксируются в Ruby::V4::Any.
    def flatten(a : Array, depth : Int) : Array(Any)
      out = [] of Any
      a.each do |x|
        if x.is_a?(Array) && depth > 0
          flatten(x, depth - 1).each { |y| out << y }
        elsif x.is_a?(Array)
          out << Any.new(Any.wrap(x))
        else
          out << Any.new(x)
        end
      end
      out
    end
  end
end

# Боксер для гетерогенных рекурсивных значений (аналог Object в Ruby-массивах).
module Ruby
  module V4
    class Any
      alias Value = Nil | Bool | Int32 | Int64 | Float64 | String | Array(Any)

      property value : Value

      def initialize(@value : Value)
      end

      def self.wrap(a : Array) : Array(Any)
        a.map { |e| e.is_a?(Array) ? Any.new(wrap(e)) : Any.new(e.as(Value)) }
      end
    end
  end
end
