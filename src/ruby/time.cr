# Ruby::V4::Time — обёртка над Crystal::Time с семантикой Ruby:
# to_s/inspect "2026-01-02 03:04:05 +0530" / "... UTC", собственный
# strftime с флагами -_^0 и %N/%L, iso8601/xmlschema/httpdate/rfc2822,
# ограниченный Time.parse, to_a, weekday-методы, арифметика в секундах.

module Ruby
  module V4
    class Time
      include Comparable(self)

      @t : ::Time
      # Метка зоны: "UTC" (или nil — числовой офсет при выводе)
      @zone : String?
      # Точная дробная часть (Rational) для subsec — как Ruby.
      @subsec : Rational = Rational.new(0_i64, 1_i64)

      def initialize(@t : ::Time, @zone : String? = nil, @subsec : Rational = Rational.new(0_i64, 1_i64))
      end

      # --- конструкторы ---

      def self.now : self
        new(::Time.local)
      end

      # Time.at — локальное время (как в Ruby): Time.at(0).to_s в MSK
      # даёт "1970-01-01 03:00:00 +0300".
      def self.at(seconds : Int) : self
        new(::Time.unix(seconds).in(::Time::Location.local))
      end

      def self.at(seconds : Float) : self
        sec = seconds.floor.to_i64
        # Наносекунды в расширенной точности: floor(|x|*1e9) должен
        # совпадать с Ruby (рациональная интерпретация double),
        # например 0.123456789 → 123456788, а не 123456789.
        nsec = (BigFloat.new(seconds - sec) * 1_000_000_000.to_big_f).floor.to_i64
        nsec = 0 if nsec < 0
        sub = Rational.from_float(seconds - sec)
        new(::Time.unix(sec).in(::Time::Location.local) + ::Time::Span.new(nanoseconds: nsec.to_i32), nil, sub)
      end

      # Time.at(sec, frac, unit): :millisecond / :usec / :nanosecond.
      def self.at(seconds : Int, frac : Int, unit : Symbol = :usec) : self
        nsec = case unit
               when :millisecond, :msec then frac * 1_000_000
               when :microsecond, :usec then frac * 1_000
               when :nanosecond, :nsec  then frac
               else
                 raise ArgumentError.new("invalid unit: #{unit.inspect}")
               end
        sub = Rational.from_ratio(nsec, 1_000_000_000)
        new(::Time.unix(seconds.to_i64).in(::Time::Location.local) +
          ::Time::Span.new(nanoseconds: nsec), nil, sub)
      end

      def self.utc(year : Int, mon = 1, day = 1, hour = 0, min = 0, sec = 0, usec = 0) : self
        new(::Time.utc(year, mon, day, hour, min, sec, nanosecond: usec * 1000), "UTC")
      end

      def self.gm(*args) : self
        utc(*args)
      end

      def self.local(year : Int, mon = 1, day = 1, hour = 0, min = 0, sec = 0, usec = 0) : self
        new(::Time.local(year, mon, day, hour, min, sec, nanosecond: usec * 1000))
      end

      def self.mktime(*args) : self
        local(*args)
      end

      # Time.new(...) — сейчас; Time.new(y, m, d, h, min, s, zone);
      # zone: строка "+05:30"/"-03:00"/"UTC", либо Int-офсет в секундах.
      def self.new(year : Int, mon = 1, day = 1, hour = 0, min = 0, sec = 0,
                   zone : String | Int | Nil = nil) : self
        case zone
        when Nil
          local(year, mon, day, hour, min, sec)
        when String
          if zone == "UTC"
            utc(year, mon, day, hour, min, sec)
          else
            off = zone_offset(zone)
            # Стенное время в зоне с офсетом: момент = стена − офсет.
            t = (::Time.utc(year, mon, day, hour, min, sec) - off.seconds)
              .in(::Time::Location.fixed(off))
            new(t)
          end
        when Int
          t = (::Time.utc(year, mon, day, hour, min, sec) - zone.seconds)
            .in(::Time::Location.fixed(zone))
          new(t)
        else
          raise ArgumentError.new("invalid zone: #{zone.inspect}")
        end
      end

      def self.new : self
        now
      end

      def self.zone_offset(str : String) : Int32
        if (m = str.match(/\A([+-])(\d{2}):?(\d{2})\z/))
          sign = m[1] == "-" ? -1 : 1
          sign * (m[2].to_i * 3600 + m[3].to_i * 60)
        else
          raise ArgumentError.new("invalid zone: #{str.inspect}")
        end
      end

      # strptime: %Y %m %d %y %H %M %S (жадно, без ведущего нуля — как
      # Date._strptime: %H читает и "7", и "07") + буквальные символы.
      # Результат — локальное время.
      def self.strptime(str : String, fmt : String) : self
        y = 1970
        mo = 1
        d = 1
        h = 0
        mi = 0
        s = 0
        si = 0
        fi = 0
        while fi < fmt.size
          c = fmt[fi]
          if c == '%'
            dir = fmt[fi + 1]? || raise ArgumentError.new("strptime: висячий %")
            fi += 2
            max = dir == 'Y' ? 4 : 2
            start = si
            while si < str.size && si - start < max && str[si].ascii_number?
              si += 1
            end
            raise ArgumentError.new("strptime: ожидались цифры (%#{dir})") if si == start
            v = str[start...si].to_i
            case dir
            when 'Y' then y = v
            when 'y' then y = v < 69 ? v + 2000 : v + 1900
            when 'm' then mo = v
            when 'd' then d = v
            when 'H' then h = v
            when 'M' then mi = v
            when 'S' then s = v
            else raise ArgumentError.new("strptime: неподдерживаемая директива %#{dir}")
            end
          else
            unless str[si]? == c
              raise ArgumentError.new("strptime: несовпадение формата на #{si}")
            end
            fi += 1
            si += 1
          end
        end
        local(y, mo, d, h, mi, s)
      end

      # --- базовые ---

      def to_i : Int64
        @t.to_unix
      end

      def to_f : Float64
        @t.to_unix_f
      end

      def utc_offset : Int32
        @t.location.lookup(@t).offset
      end

      def zone : String?
        return "UTC" if @zone == "UTC"
        # Аббревиатура именованной зоны (MSK); фиксированный офсет в Crystal
        # даёт имя вида "+03" — Ruby в этом случае возвращает nil.
        name = @t.location.lookup(@t).name
        name.starts_with?(/[+-]\d/) ? nil : name
      end

      # Точная дробная часть как Rational: Time.at(0.5).subsec → (1/2).
      def subsec : Rational
        @subsec
      end

      # --- мосты к Date/DateTime ---

      def to_date : Date
        Date.civil(year, mon, day)
      end

      def to_datetime : DateTime
        DateTime.civil(year, mon, day, hour, min, sec, utc_offset)
      end

      # round/ceil с точностью digits знаков субсекунды, half-up с переносом
      # в секунду (Ruby: Time#round(3) у 0.999999999 → 1.000000000).
      def round(digits : Int = 0) : self
        unit = (10 ** (9 - digits)).to_i64
        quantized_subsec((nsec + unit // 2) // unit * unit)
      end

      def ceil(digits : Int = 0) : self
        unit = (10 ** (9 - digits)).to_i64
        quantized_subsec((nsec + unit - 1) // unit * unit)
      end

      private def quantized_subsec(n : Int64) : self
        sec = to_i
        if n >= 1_000_000_000
          sec += 1
          n -= 1_000_000_000
        end
        t = (::Time.unix(sec) + ::Time::Span.new(nanoseconds: n.to_i32)).in(@t.location)
        Time.new(t, @zone, Rational.from_ratio(n, 1_000_000_000))
      end

      def utc? : Bool
        @zone == "UTC"
      end

      def dst? : Bool
        @t.location.lookup(@t).dst?
      end

      def getutc : self
        Time.new(@t.in(::Time::Location::UTC), "UTC")
      end

      def getlocal : self
        Time.new(@t.in(::Time::Location.local))
      end

      def utc : self
        @t = @t.in(::Time::Location::UTC)
        @zone = "UTC"
        self
      end

      def localtime : self
        @t = @t.in(::Time::Location.local)
        @zone = nil
        self
      end

      # --- компоненты (в своей зоне) ---

      def year : Int32
        @t.year
      end

      def mon : Int32
        @t.month
      end

      def month : Int32
        mon
      end

      def day : Int32
        @t.day
      end

      def mday : Int32
        day
      end

      def hour : Int32
        @t.hour
      end

      def min : Int32
        @t.minute
      end

      def sec : Int32
        @t.second
      end

      def nsec : Int32
        @t.nanosecond
      end

      def usec : Int32
        nsec // 1000
      end

      def wday : Int32
        days = to_i // 86400
        (((days % 7) + 11) % 7).to_i32 # 1970-01-01 = четверг (4)
      end

      def yday : Int32
        cum = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
        y = year
        d = day
        if Date.leap?(y) && mon > 2
          d += 1
        end
        cum[mon - 1] + d
      end

      {% for d, i in %w[sunday monday tuesday wednesday thursday friday saturday] %}
        def {{d.id}}? : Bool
          wday == {{i}}
        end
      {% end %}

      def to_a : Array(String | Int32 | Bool)
        [sec, min, hour, mday, mon, year, wday, yday, dst?, @zone || offset_str]
      end

      # --- сравнение/арифметика ---

      def +(seconds : Int) : self
        Time.new(@t + seconds.seconds, @zone)
      end

      def +(seconds : Float) : self
        sec = seconds.floor.to_i64
        nsec = ((seconds - sec) * 1e9).round.to_i32
        Time.new(@t + ::Time::Span.new(seconds: sec, nanoseconds: nsec), @zone)
      end

      def -(seconds : Int) : self
        self + (-seconds)
      end

      def -(other : self) : Float64
        (to_f - other.to_f)
      end

      def <=>(other : self) : Int32
        c = to_f <=> other.to_f
        c || 0
      end

      def ==(other : self) : Bool
        to_i == other.to_i && nsec == other.nsec
      end

      # --- вывод ---

      def to_s : String
        base = format_parts("%Y-%m-%d %H:%M:%S")
        if @zone == "UTC"
          "#{base} UTC"
        else
          "#{base} #{offset_str}"
        end
      end

      # inspect показывает дробную часть ("03:00:01.5 +0300"), to_s — нет.
      def inspect : String
        s = to_s
        return s if nsec == 0
        frac = "." + nsec.to_s.rjust(9, '0').rstrip('0')
        s = s.insert(19, frac) if s.bytesize >= 19
        s
      end

      def offset_str(colons : Int32 = 0) : String
        off = utc_offset
        sign = off < 0 ? '-' : '+'
        a = off.abs
        case colons
        when 1 then Kernel.format("%c%02d:%02d", sign, a // 3600, (a % 3600) // 60)
        when 2 then Kernel.format("%c%02d:%02d:%02d", sign, a // 3600, (a % 3600) // 60, a % 60)
        else        Kernel.format("%c%02d%02d", sign, a // 3600, (a % 3600) // 60)
        end
      end

      def iso8601(fraction_digits = 0) : String
        xmlschema(fraction_digits)
      end

      def xmlschema(fraction_digits = 0) : String
        b = String::Builder.new
        b << format_parts("%Y-%m-%dT%H:%M:%S")
        if fraction_digits > 0
          frac = nsec.to_s.rjust(9, '0')[0, fraction_digits]
          b << "." << frac
        end
        if @zone == "UTC"
          b << "Z"
        else
          off = utc_offset
          sign = off < 0 ? '-' : '+'
          a = off.abs
          b << Kernel.format("%c%02d:%02d", sign, a // 3600, (a % 3600) // 60)
        end
        b.to_s
      end

      def httpdate : String
        utc_t = getutc
        "#{DAY_S[utc_t.wday]}, #{pad2(utc_t.day)} #{MON_S[utc_t.mon - 1]} #{pad4(utc_t.year)} #{pad2(utc_t.hour)}:#{pad2(utc_t.min)}:#{pad2(utc_t.sec)} GMT"
      end

      def rfc2822 : String
        u = utc? ? self : self
        off = utc?
        off_str = utc? ? "-0000" : offset_str
        "#{DAY_S[wday]}, #{pad2(day)} #{MON_S[mon - 1]} #{pad4(year)} #{pad2(hour)}:#{pad2(min)}:#{pad2(sec)} #{off_str}"
      end

      DAY_S = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
      DAY_L = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
      MON_S = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
      MON_L = ["January", "February", "March", "April", "May", "June", "July",
               "August", "September", "October", "November", "December"]

      # --- strftime с семантикой Ruby ---

      def strftime(fmt : String) : String
        out = String::Builder.new
        i = 0
        n = fmt.bytesize
        while i < n
          c = fmt.byte_at(i)
          if c != '%'.ord
            out.write_byte(c)
            i += 1
            next
          end
          j = i + 1
          dash = false
          underscore = false
          caret = false
          zeroflag = false
          colons = 0
          while j < n
            case fmt.byte_at(j)
            when '-'.ord then dash = true
            when '_'.ord then underscore = true
            when '^'.ord then caret = true
            when '0'.ord then zeroflag = true
            when ':'.ord then colons += 1
            else           break
            end
            j += 1
          end
          width = 0
          while j < n && fmt.byte_at(j).chr.ascii_number?
            width = width * 10 + (fmt.byte_at(j) - '0'.ord)
            j += 1
          end
          break (out << fmt[i..]) if j >= n
          conv = fmt.byte_at(j).chr
          body = directive(conv, width, dash, underscore, zeroflag, colons)
          if body.nil?
            out << fmt[i..j]
          else
            out << (caret ? body.upcase : body)
          end
          i = j + 1
        end
        out.to_s
      end

      # значение одной директивы (без флагов); nil → неизвестная директива
      private def directive(conv : Char, width : Int32,
                            dash : Bool, underscore : Bool, zeroflag : Bool,
                            colons : Int32 = 0) : String?
        case conv
        when 'Y' then num(year, 0, width, dash, underscore, zeroflag)
        when 'C' then num(year // 100, 2, width, dash, underscore, zeroflag)
        when 'y' then num(year % 100, 2, width, dash, underscore, zeroflag)
        when 'm' then num(mon, 2, width, dash, underscore, zeroflag)
        when 'd' then num(day, 2, width, dash, underscore, zeroflag)
        when 'e' then num_sp(day, width, dash, underscore, zeroflag)
        when 'H' then num(hour, 2, width, dash, underscore, zeroflag)
        when 'k' then num_sp(hour, width, dash, underscore, zeroflag)
        when 'I' then num(hour12, 2, width, dash, underscore, zeroflag)
        when 'l' then num_sp(hour12, width, dash, underscore, zeroflag)
        when 'M' then num(min, 2, width, dash, underscore, zeroflag)
        when 'S' then num(sec, 2, width, dash, underscore, zeroflag)
        when 'L' then frac_digits(3, width)
        when 'N' then frac_digits(9, width)
        when 'j' then num(yday, 3, width, dash, underscore, zeroflag)
        when 'u' then num(wday == 0 ? 7 : wday, 0, width, dash, underscore, zeroflag)
        when 'w' then num(wday, 0, width, dash, underscore, zeroflag)
        when 'a' then DAY_S[wday]
        when 'A' then DAY_L[wday]
        when 'b', 'h' then MON_S[mon - 1]
        when 'B' then MON_L[mon - 1]
        when 'p' then hour < 12 ? "AM" : "PM"
        when 'P' then hour < 12 ? "am" : "pm"
        when 's' then to_i.to_s
        when 'z' then offset_str(colons)
        when 'Z' then zone || ""
        when 'n' then "\n"
        when 't' then "\t"
        when '%' then "%"
        when 'G' then num(iso_week_year, 0, width, dash, underscore, zeroflag)
        when 'V' then num(iso_week_num, 2, width, dash, underscore, zeroflag)
        when 'U' then num((yday + 6 - wday) // 7, 2, width, dash, underscore, zeroflag)
        when 'W' then num((yday + 7 - (wday == 0 ? 6 : wday - 1)) // 7, 2, width, dash, underscore, zeroflag)
        when 'D' then strftime_static("%m/%d/%y")
        when 'F' then strftime_static("%Y-%m-%d")
        when 'T' then strftime_static("%H:%M:%S")
        when 'R' then strftime_static("%H:%M")
        when 'r' then strftime_static("%I:%M:%S %p")
        when 'X' then strftime_static("%H:%M:%S")
        when 'x' then strftime_static("%m/%d/%y")
        when 'c' then strftime_static("%a %b %e %H:%M:%S %Y")
        else      nil
        end
      end

      private def iso_week_year : Int32
        d = Date.new(year, mon, day)
        d.cweek_year[0]
      end

      private def iso_week_num : Int32
        d = Date.new(year, mon, day)
        d.cweek_year[1]
      end

      private def strftime_static(fmt) : String
        strftime(fmt)
      end

      # Числовая директива: def_width — ширина по умолчанию, паддинг нулями.
      private def num(v : Int32, def_width : Int32, width : Int32,
                      dash : Bool, underscore : Bool, zeroflag : Bool,
                      default_pad : Char = '0') : String
        return v.to_s if dash
        ch = underscore ? ' ' : (zeroflag ? '0' : default_pad)
        w = {width, def_width}.max
        v.to_s.rjust(w, ch)
      end

      private def num_sp(v : Int32, width : Int32,
                         dash : Bool, underscore : Bool, zeroflag : Bool) : String
        num(v, 2, width, dash, underscore, zeroflag, ' ')
      end

      private def frac_digits(default : Int32, width : Int32) : String
        digits = width > 0 ? width : default
        frac = nsec.to_s.rjust(9, '0')[0, digits]
        frac
      end

      private def hour12 : Int32
        h = hour % 12
        h == 0 ? 12 : h
      end

      private def format_parts(fmt : String) : String
        strftime(fmt)
      end

      private def pad2(v : Int) : String
        v.to_s.rjust(2, '0')
      end

      private def pad3(v : Int) : String
        v.to_s.rjust(3, '0')
      end

      private def pad4(v : Int) : String
        v.to_s.rjust(4, '0')
      end

      # --- parse ---

      def self.parse(str : String) : self
        # httpdate/rfc2822: "Fri, 02 Jan 2026 03:04:05 GMT" или "+0300"
        if (m = str.match(/\A(?:\w{3}, )?(\d{1,2}) (\w{3}) (\d{4}) (\d{2}):(\d{2}):(\d{2}) (UTC|GMT|Z|[+-]\d{2}:?\d{2})\z/))
          mon = MON_S.index(m[2]).not_nil! + 1
          zone_str = m[7]
          t = ::Time.utc(m[3].to_i, mon, m[1].to_i, m[4].to_i, m[5].to_i, m[6].to_i)
          return case zone_str
                 when "UTC", "Z" then new(t, "UTC")
                 when "GMT"      then new(t)
                 else
                   off = zone_offset(zone_str)
                   new((t - off.seconds).in(::Time::Location.fixed(off)))
                 end
        end
        # ISO-подобные: "2026[-/]01[-/]02[T ]03:04:05[.frac][ UTC|Z|GMT|±HH:MM|±HHMM]"
        # Время опционально: "2026-01-02" → локальная полночь.
        if (m = str.match(/\A(\d{4})[-\/](\d{1,2})[-\/](\d{1,2})(?:[T ](\d{2}):(\d{2})(?::(\d{2}))?(?:\.(\d+))?)?\s*(UTC|Z|GMT|[+-]\d{2}:?\d{2})?\z/))
          hour = m[4]?.try &.to_i || 0
          minute = m[5]?.try &.to_i || 0
          second = m[6]?.try &.to_i || 0
          frac = m[7]?
          nsec = frac ? (frac[0, 9].to_i * (10 ** (9 - frac[0, 9].size))) : 0
          sub = frac ? Rational.from_ratio(frac[0, 9].to_i, 10 ** frac[0, 9].size) : Rational.new(0_i64, 1_i64)
          case zone_str = m[8]?
          when Nil
            t = ::Time.local(m[1].to_i, m[2].to_i, m[3].to_i, hour, minute, second,
              nanosecond: nsec)
            new(t, nil, sub)
          when "UTC", "Z"
            t = ::Time.utc(m[1].to_i, m[2].to_i, m[3].to_i, hour, minute, second,
              nanosecond: nsec)
            new(t, "UTC", sub)
          when "GMT"
            t = ::Time.utc(m[1].to_i, m[2].to_i, m[3].to_i, hour, minute, second,
              nanosecond: nsec)
            new(t, nil, sub)
          else
            off = zone_offset(zone_str)
            t = (::Time.utc(m[1].to_i, m[2].to_i, m[3].to_i, hour, minute, second,
              nanosecond: nsec) - off.seconds).in(::Time::Location.fixed(off))
            new(t, nil, sub)
          end
        else
          raise ArgumentError.new("Time.parse: неподдерживаемый формат: #{str.inspect}")
        end
      end
    end
  end
end
