# Kernel#format/sprintf с семантикой Ruby поверх Crystal sprintf:
# добавлены %p, %<имя>спецификация, %{имя}, %#o → префикс "0" (не "0o"),
# %c со строкой, %s с nil. Числовые конверсии делегируются Crystal sprintf,
# который совпадает с Ruby на эталонной батарее (twinshot).

module Ruby
  module V4
    module Kernel
      extend self

      # format("..."), format("...", *args), format("...", **именованные)
      def format(fmt : String, *args) : String
        internal(fmt, args.to_a)
      end

      def format(fmt : String, **named) : String
        internal(fmt, nil, named)
      end

      def format(fmt : String, args : Array) : String
        internal(fmt, args)
      end

      def format(fmt : String, hash : Hash) : String
        internal(fmt, nil, hash)
      end

      def sprintf(fmt : String, *args) : String
        format(fmt, *args)
      end

      def sprintf(fmt : String, **named) : String
        format(fmt, **named)
      end

      # --- Kernel-функции Ruby (lowercase: Integer() нельзя в Crystal) ---

      # integer(str[, base]): строгий парсер Integer() — знак,
      # префиксы 0x/0b/0o/0d, подчёркивания между цифрами, пробелы по краям;
      # мусор → ArgumentError.
      def integer(str : String, base : Int = 10) : Int64
        s = str.strip
        raise ArgumentError.new("invalid value for Integer(): #{str.inspect}") if s.empty?
        sign = 1_i64
        if s[0] == '-' || s[0] == '+'
          sign = -1_i64 if s[0] == '-'
          s = s[1..]
        end
        prefixes = {16 => {"0x", "0X"}, 2 => {"0b", "0B"}, 8 => {"0o", "0O"}}
        if (prefs = prefixes[base]?) && (s.starts_with?(prefs[0]) || s.starts_with?(prefs[1]))
          s = s[2..]
        elsif base == 16 && s.starts_with?("0X")
          s = s[2..]
        elsif base == 8 && s.starts_with?("0") && s.size > 1
          s = s[1..]
        elsif base == 10 && (s.starts_with?("0d") || s.starts_with?("0D"))
          s = s[2..]
        end
        raise ArgumentError.new("invalid value for Integer(): #{str.inspect}") if s.empty?
        val = 0_i64
        prev_us = true # подряд идущие подчёркивания запрещены
        s.each_char do |c|
          if c == '_'
            raise ArgumentError.new("invalid value for Integer(): #{str.inspect}") if prev_us
            prev_us = true
            next
          end
          digit = c.to_i?(base)
          raise ArgumentError.new("invalid value for Integer(): #{str.inspect}") unless digit
          val = val * base + digit
          prev_us = false
        end
        raise ArgumentError.new("invalid value for Integer(): #{str.inspect}") if prev_us && val.zero? && s.includes?('_')
        sign * val
      end

      def float(str : String) : Float64
        s = str.strip
        unless s.matches?(/\A[+-]?(\d+\.?\d*|\.\d+)(e[+-]?\d+)?\z/i)
          raise ArgumentError.new("invalid value for Float(): #{str.inspect}")
        end
        s.to_f
      end

      def rational(num : Int, den : Int = 1) : ::Ruby::V4::Rational
        ::Ruby::V4::Rational.from_ratio(num, den)
      end

      # array(nil) → [], array(range) → to_a, array(массив) → он сам,
      # прочее → [x] (Kernel#Array в Ruby).
      def array(value : Nil) : Array(Nil)
        [] of Nil
      end

      def array(value : Array) : Array
        value
      end

      def array(value : Range) : Array
        value.to_a
      end

      def array(value) : Array
        [value]
      end

      def hash_of(pairs : Array) : Hash
        pairs.to_h
      end

      private class ThrowSignal < Exception
        getter tag : Symbol
        getter value : Int32 | Float64 | String | Nil

        def initialize(@tag : Symbol, @value : Int32 | Float64 | String | Nil)
          super("uncaught throw #{@tag}")
        end
      end

      # catch/throw как в Ruby (через исключение-сигнал).
      def catch(tag : Symbol, &block : Symbol -> _)
        yield tag
      rescue e : ThrowSignal
        e.tag == tag ? e.value : raise e
      end

      def throw(tag : Symbol, value = nil)
        raise ThrowSignal.new(tag, value)
      end

      private def internal(fmt : String, args : Array? = nil,
                           named : NamedTuple | Hash | Nil = nil) : String
        out_str = String::Builder.new
        bytes = fmt.to_slice
        i = 0
        arg_i = 0
        while i < bytes.size
          c = bytes[i]
          if c != '%'.ord
            out_str.write_byte(c)
            i += 1
            next
          end
          j = i + 1

          # %{имя} — подстановка to_s
          if j < bytes.size && bytes[j] == '{'.ord
            close = fmt.index('}', j)
            raise ArgumentError.new("malformed format string") unless close
            name = fmt[(j + 1)...close]
            out_str << named_value(named, name).to_s
            i = close + 1
            next
          end

          # %<имя>спецификация
          if j < bytes.size && bytes[j] == '<'.ord
            close = fmt.index('>', j)
            raise ArgumentError.new("malformed format string") unless close
            name = fmt[(j + 1)...close]
            spec_start = close + 1
            spec_end = directive_end(bytes, spec_start)
            spec = fmt[spec_start...spec_end]
            out_str << format_one(spec, named_value(named, name))
            i = spec_end
            next
          end

          spec_end = directive_end(bytes, j)
          spec = fmt[i...spec_end]
          body = apply_directive(spec, args, pointerof(arg_i))
          out_str << body if body
          i = spec_end
        end
        out_str.to_s
      end

      private def named_value(named : NamedTuple | Hash | Nil, name : String)
        h = named || raise ArgumentError.new("named argument not given")
        if h.is_a?(NamedTuple)
          h[name]? || raise KeyError.new("key not found: #{name.inspect}")
        else
          h.fetch(name) { raise KeyError.new("key not found: #{name.inspect}") }
        end
      end

      # Конец директивы: позиция после символа конверсии.
      private def directive_end(bytes : Bytes, start : Int) : Int
        j = start
        # позиционный N$
        if j < bytes.size && bytes[j].chr.ascii_number?
          k = j
          while k < bytes.size && bytes[k].chr.ascii_number?
            k += 1
          end
          if k < bytes.size && bytes[k] == '$'.ord
            j = k + 1
          end
        end
        # флаги
        while j < bytes.size && "-+ 0#".includes?(bytes[j].chr)
          j += 1
        end
        # ширина
        while j < bytes.size && bytes[j].chr.ascii_number?
          j += 1
        end
        # точность
        if j < bytes.size && bytes[j] == '.'.ord
          j += 1
          while j < bytes.size && bytes[j].chr.ascii_number?
            j += 1
          end
        end
        # конверсия
        j += 1 if j < bytes.size
        j
      end

      # Обработка одной обычной директивы; nil → напечатать буквально.
      private def apply_directive(spec : String, args : Array?, arg_i : Int32*) : String?
        return "%" if spec == "%%"
        conv = spec[-1]?
        return spec if conv.nil? || !conv.ascii_letter?
        return spec if spec.size == 1 # "%" в конце

        # позиционная конверсия %N$...
        if (pm = spec.match(/\A%(\d+)\$(.*)\z/m))
          idx = pm[1].to_i - 1
          inner = pm[2]
          return format_one(inner, args.not_nil![idx]) if args
        end

        val = args.try &.[arg_i.value]?
        arg_i.value += 1
        format_one(spec[1..], val)
      end

      # Одна конверсия (без %) со значением: делегирует Crystal sprintf,
      # обрабатывая несовместимые случаи вручную.
      def format_one(spec : String, val) : String
        conv = spec[-1]
        case conv
        when 'p'
          s = Ruby::V4.inspect(val)
          pad_spec(spec[0...-1], s)
        when 'c'
          s = case val
              when String then val[0].to_s
              when Char   then val.to_s
              when Int    then val.chr.to_s
              else             val.to_s
              end
          pad_spec(spec[0...-1], s)
        when 's'
          if val.nil?
            pad_spec(spec[0...-1], "")
          elsif spec.includes?('#')
            ::sprintf("%#{spec.tr("#", "")}", val)
          else
            ::sprintf("%#{spec}", val)
          end
        when 'o'
          s = ::sprintf("%#{spec}", val)
          if spec.includes?('#') && !s.starts_with?('-')
            s = s.sub("0o", "0")
          elsif spec.includes?('#')
            s = s.sub("-0o", "-0")
          end
          s
        else
          # числовые и прочие конверсии — Crystal sprintf совместим
          ::sprintf("%#{spec}", val)
        end
      end

      private def pad_spec(flags : String, s : String) : String
        m = flags.match(/\A([-+ 0#]*)(\d+)?\z/)
        width = m.try &.[2]?.try &.to_i || 0
        return s if width <= s.size
        if flags.includes?('-')
          s.ljust(width)
        else
          s.rjust(width, flags.includes?('0') ? '0' : ' ')
        end
      end
    end
  end
end

# Ruby::V4.format(...) → Kernel.format
module Ruby::V4
  extend Kernel
end
