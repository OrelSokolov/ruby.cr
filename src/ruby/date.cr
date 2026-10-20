# Ruby::V4::Date / DateTime — собственная арифметика на юлианской дате (JD)
# с григорианской реформой 1582-10-15 (Date::ITALY, как в Ruby по умолчанию).

module Ruby
  module V4
    class Date
      include Comparable(self)

      REFORM_JD = 2299161 # JD григорианской 1582-10-15

      @jd : Int64

      def initialize(@jd : Int64)
      end

      def self.civil(year : Int, mon = 1, day = 1) : self
        new(civil_to_jd(year, mon, day))
      end

      def self.new(year : Int, mon = 1, day = 1) : self
        civil(year, mon, day)
      end

      # JD григорианской даты (формула Ричардса/Флигеля).
      private def self.gregorian_jd(y : Int64, m : Int64, d : Int64) : Int64
        a = (14 - m) // 12
        y2 = y + 4800 - a
        m2 = m + 12 * a - 3
        d + (153 * m2 + 2) // 5 + 365 * y2 + y2 // 4 - y2 // 100 + y2 // 400 - 32045
      end

      private def self.julian_jd(y : Int64, m : Int64, d : Int64) : Int64
        a = (14 - m) // 12
        y2 = y + 4800 - a
        m2 = m + 12 * a - 3
        d + (153 * m2 + 2) // 5 + 365 * y2 + y2 // 4 - 32083
      end

      def self.civil_to_jd(y : Int, m : Int, d : Int) : Int64
        g = gregorian_jd(y.to_i64, m.to_i64, d.to_i64)
        g >= REFORM_JD ? g : julian_jd(y.to_i64, m.to_i64, d.to_i64)
      end

      # Обратно: {год, месяц, день} в календаре, действующем на этот JD.
      def self.jd_to_civil(jd : Int64) : Tuple(Int64, Int64, Int64)
        if jd >= REFORM_JD
          a = jd + 32044
          b = (4 * a + 3) // 146097
          c = a - (146097 * b) // 4
        else
          b = 0_i64
          c = jd + 32082
        end
        d = (4 * c + 3) // 1461
        e = c - (1461 * d) // 4
        m = (5 * e + 2) // 153
        day = e - (153 * m + 2) // 5 + 1
        mon = m + 3 - 12 * (m // 10)
        year = 100 * b + d - 4800 + m // 10
        {year.to_i64, mon.to_i64, day.to_i64}
      end

      def self.jd(jd : Int) : self
        new(jd.to_i64)
      end

      def self.ordinal(year : Int, day : Int) : self
        jan1 = civil(year, 1, 1)
        new(jan1.jd + day - 1)
      end

      # Коммерческая (ISO) неделя.
      def self.commercial(cwyear : Int, cweek : Int, cwday : Int) : self
        jan4 = civil(cwyear, 1, 4)
        week1_monday = jan4.jd - (jan4.cwday - 1)
        new(week1_monday + (cweek - 1) * 7 + (cwday - 1))
      end

      def self.today : self
        now = ::Time.local
        civil(now.year, now.month, now.day)
      end

      def self.parse(str : String) : self
        if (m = str.match(/\A(\d{4})-(\d{2})-(\d{2})\z/))
          civil(m[1].to_i, m[2].to_i, m[3].to_i)
        elsif (m = str.match(/\A(\d{4})\/(\d{1,2})\/(\d{1,2})\z/))
          civil(m[1].to_i, m[2].to_i, m[3].to_i)
        elsif (m = str.match(/\A(\d{8})\z/)) # ISO basic: 20260102
          civil(m[1][0, 4].to_i, m[1][4, 2].to_i, m[1][6, 2].to_i)
        elsif (m = str.match(/\A(\d{4})-W(\d{2})-(\d)\z/)) # ISO week: 2026-W01-1
          commercial(m[1].to_i, m[2].to_i, m[3].to_i)
        elsif (m = str.match(/\A([A-Za-z]+) (\d{1,2}), (\d{4})\z/)) # January 2, 2026
          civil(m[3].to_i, month_from_name(m[1]), m[2].to_i)
        elsif (m = str.match(/\A([A-Za-z]+) (\d{1,2}) (\d{4})\z/)) # Jan 2 2026
          civil(m[3].to_i, month_from_name(m[1]), m[2].to_i)
        elsif (m = str.match(/\A(\d{1,2}) ([A-Za-z]+) (\d{4})\z/)) # 2 Jan 2026
          civil(m[3].to_i, month_from_name(m[2]), m[1].to_i)
        else
          raise ArgumentError.new("Date.parse: неподдерживаемый формат: #{str.inspect}")
        end
      end

      # strptime: мини-парсер форматов (%Y %m %d %y + буквальные разделители).
      def self.strptime(str : String, fmt : String) : self
        y = 0
        m = 1
        d = 1
        si = 0
        fi = 0
        while fi < fmt.size
          c = fmt[fi]
          if c == '%' && fi + 1 < fmt.size
            dir = fmt[fi + 1]
            fi += 2
            width = {'Y' => 4, 'y' => 2, 'm' => 2, 'd' => 2}.fetch(dir, 0)
            raise ArgumentError.new("strptime: неподдерживаемая директива %#{dir}") if width == 0
            raise ArgumentError.new("strptime: строка кончилась (%#{dir})") if si + width > str.size
            v = str[si, width].to_i?
            raise ArgumentError.new("strptime: ожидались цифры (%#{dir})") unless v
            case dir
            when 'Y' then y = v
            when 'y' then y = v < 69 ? 2000 + v : 1900 + v
            when 'm' then m = v
            when 'd' then d = v
            end
            si += width
          else
            raise ArgumentError.new("strptime: несовпадение формата на #{si}") if str[si]? != c
            si += 1
            fi += 1
          end
        end
        civil(y, m, d)
      end

      # Индекс месяца по полному/сокращённому имени (регистронезависимо).
      private def self.month_from_name(name : String) : Int32
        lower = name.downcase
        idx = Time::MON_S.index { |m| m.downcase == lower } ||
              Time::MON_L.index { |m| m.downcase == lower }
        raise ArgumentError.new("invalid month name: #{name.inspect}") unless idx
        idx + 1
      end

      def self.iso8601(str : String) : self
        parse(str)
      end

      # Мост к DateTime (полночь UTC, как в Ruby).
      def to_datetime : DateTime
        DateTime.civil(year, mon, day, 0, 0, 0, 0)
      end

      # Мост к Time: локальная полночь (как в Ruby Date#to_time).
      def to_time : Time
        Time.new(::Time.local(year, mon, day))
      end

      def self.leap?(year : Int) : Bool
        year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
      end

      def self.gregorian_leap?(year : Int) : Bool
        leap?(year)
      end

      # --- атрибуты ---

      def jd : Int64
        @jd
      end

      def mjd : Int64
        @jd - 2400001
      end

      def civil : Tuple(Int64, Int64, Int64)
        Date.jd_to_civil(@jd)
      end

      def year : Int32
        civil[0].to_i32
      end

      def mon : Int32
        civil[1].to_i32
      end

      def month : Int32
        mon
      end

      def day : Int32
        civil[2].to_i32
      end

      def mday : Int32
        day
      end

      def wday : Int32
        ((@jd + 1) % 7).to_i32 # 0 = воскресенье
      end

      def cwday : Int32
        (wday == 0 ? 7 : wday)
      end

      # ISO-неделя: {iso-год, неделя}. Стандартный алгоритм через «четверг
      # этой недели».
      def cweek_year : Tuple(Int32, Int32)
        thursday = @jd + (4 - cwday)
        ty = Date.jd_to_civil(thursday)[0]
        jan4 = Date.civil(ty.to_i32, 1, 4)
        week1 = jan4.jd - (jan4.cwday - 1)
        {ty.to_i32, ((@jd - week1) // 7 + 1).to_i32}
      end

      def cweek : Int32
        cweek_year[1]
      end

      def cwyear : Int32
        cweek_year[0]
      end

      def yday : Int32
        jan1 = Date.civil(year, 1, 1).jd
        (@jd - jan1 + 1).to_i32
      end

      def julian? : Bool
        @jd < REFORM_JD
      end

      def gregorian? : Bool
        !julian?
      end

      {% for d, i in %w[sunday monday tuesday wednesday thursday friday saturday] %}
        def {{d.id}}? : Bool
          wday == {{i}}
        end
      {% end %}

      # --- арифметика ---

      def +(days : Int) : self
        Date.new(@jd + days)
      end

      def -(days : Int) : self
        Date.new(@jd - days)
      end

      def -(other : self) : Int64
        @jd - other.jd
      end

      def succ : self
        self + 1
      end

      def next_day(n = 1) : self
        self + n
      end

      def prev_day(n = 1) : self
        self - n
      end

      def next_month(n = 1) : self
        shift_month(n)
      end

      def prev_month(n = 1) : self
        shift_month(-n)
      end

      # Ruby month-arithmetic: Date >> n / Date << n (с клампингом дня).
      def >>(n : Int) : self
        shift_month(n)
      end

      def <<(n : Int) : self
        shift_month(-n)
      end

      def next_year(n = 1) : self
        shift_month(12 * n)
      end

      def prev_year(n = 1) : self
        shift_month(-12 * n)
      end

      private def shift_month(delta : Int) : self
        y, m, d = civil
        total = (y * 12 + (m - 1)) + delta
        ny = total // 12
        nm = total % 12 + 1
        nd = {d.to_i64, days_in_month(ny, nm)}.min
        Date.new(Date.civil_to_jd(ny.to_i32, nm.to_i32, nd.to_i32))
      end

      private def days_in_month(y : Int64, m : Int64) : Int64
        case m
        when 1, 3, 5, 7, 8, 10, 12 then 31_i64
        when 4, 6, 9, 11           then 30_i64
        else                            Date.leap?(y.to_i32) ? 29_i64 : 28_i64
        end
      end

      def <=>(other : self) : Int32
        @jd <=> other.jd
      end

      def ==(other : self) : Bool
        @jd == other.jd
      end

      def between?(min : self, max : self) : Bool
        self >= min && self <= max
      end

      # --- итерация (без блока — Array, см. DIFFERENCES) ---

      def step(limit : self, step : Int = 1, &block : self -> _) : Nil
        d = self
        while d <= limit
          yield d
          d += step
        end
      end

      def step(limit : self, step : Int = 1) : Array(self)
        out = [] of self
        d = self
        while d <= limit
          out << d
          d += step
        end
        out
      end

      def upto(limit : self, &block : self -> _) : Nil
        step(limit, 1) { |d| yield d }
      end

      def upto(limit : self) : Array(self)
        step(limit, 1)
      end

      def downto(limit : self, &block : self -> _) : Nil
        d = self
        while d >= limit
          yield d
          d -= 1
        end
      end

      def downto(limit : self) : Array(self)
        out = [] of self
        d = self
        while d >= limit
          out << d
          d -= 1
        end
        out
      end

      # --- вывод ---

      def to_s : String
        date_part
      end

      def date_part : String
        # Отрицательный год: знак формат separately — "%04d" % -1 даёт "-001".
        y = year
        sign = y < 0 ? "-" : ""
        Kernel.format("%s%04d-%02d-%02d", sign, y.abs, mon, day)
      end

      def iso8601 : String
        to_s
      end

      def inspect : String
        "#<Date: #{to_s} ((#{jd}j,0s,0n),+0s,#{REFORM_JD}j)>"
      end

      def asctime : String
        "#{Time::DAY_S[wday]} #{Time::MON_S[mon - 1]} #{day.to_s.rjust(2, ' ')} 00:00:00 #{Kernel.format("%04d", year)}"
      end

      def strftime(fmt : String) : String
        fmt.gsub(/%[A-Za-z%]/) do |m|
          case m
          when "%Y" then Kernel.format("%04d", year)
          when "%y" then Kernel.format("%02d", year % 100)
          when "%m" then Kernel.format("%02d", mon)
          when "%d" then Kernel.format("%02d", day)
          when "%e" then day.to_s.rjust(2, ' ')
          when "%j" then Kernel.format("%03d", yday)
          when "%A" then Time::DAY_L[wday]
          when "%a" then Time::DAY_S[wday]
          when "%B" then Time::MON_L[mon - 1]
          when "%b", "%h" then Time::MON_S[mon - 1]
          when "%u" then cwday.to_s
          when "%w" then wday.to_s
          when "%V" then Kernel.format("%02d", cweek)
          when "%G" then Kernel.format("%04d", cwyear)
          when "%%" then "%"
          else           m
          end
        end
      end
    end

    class DateTime < Date
      @daysec : Int32 # секунды суток 0..86399
      @offset : Int32 # офсет зоны в секундах

      def initialize(jd : Int64, daysec = 0, offset = 0)
        super(jd)
        @daysec = daysec
        @offset = offset
      end

      def self.civil(year : Int, mon = 1, day = 1, hour = 0, min = 0, sec = 0,
                     offset : Int | String = 0) : self
        off = offset.is_a?(String) ? Time.zone_offset(offset) : offset
        new(Date.civil_to_jd(year, mon, day), hour * 3600 + min * 60 + sec, off)
      end

      def self.jd(jd : Int, hour = 0, min = 0, sec = 0, offset : Int | String = 0) : self
        off = offset.is_a?(String) ? Time.zone_offset(offset) : offset
        new(jd.to_i64, hour * 3600 + min * 60 + sec, off)
      end

      def self.iso8601(str : String) : self
        if (m = str.match(/\A(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:([+-])(\d{2}):(\d{2})|Z)?\z/))
          off = if m[7]?
                  sign = m[7] == "-" ? -1 : 1
                  sign * (m[8].to_i * 3600 + m[9].to_i * 60)
                else
                  0
                end
          civil(m[1].to_i, m[2].to_i, m[3].to_i, m[4].to_i, m[5].to_i, m[6].to_i, off)
        else
          raise ArgumentError.new("DateTime.iso8601: #{str.inspect}")
        end
      end

      # DateTime.parse — ISO-подобные строки с временем и офсетом.
      def self.parse(str : String) : self
        iso8601(str)
      end

      # --- мосты ---

      def to_date : Date
        Date.new(@jd)
      end

      # Тот же момент в зоне с собственным офсетом даты-времени
      # (Ruby >= 2.5: DateTime#to_time сохраняет офсет).
      def to_time : Time
        t = (::Time.utc(year, mon, day, hour, min, sec) - @offset.seconds)
          .in(::Time::Location.fixed(@offset))
        Time.new(t)
      end

      def daysec : Int32
        @daysec
      end

      def hour : Int32
        @daysec // 3600
      end

      def min : Int32
        (@daysec % 3600) // 60
      end

      def sec : Int32
        @daysec % 60
      end

      def offset : Int32
        @offset
      end

      # Смена зоны с сохранением момента: стенное время сдвигается на
      # разницу офсетов (новый − старый).
      def new_offset(offset : Int | String) : self
        off = offset.is_a?(String) ? Time.zone_offset(offset) : offset
        shifted = @daysec + (off - @offset)
        jd = @jd
        if shifted >= 86400
          jd += 1
          shifted -= 86400
        elsif shifted < 0
          jd -= 1
          shifted += 86400
        end
        DateTime.new(jd, shifted, off)
      end

      def +(days : Int) : DateTime
        DateTime.new(@jd + days, @daysec, @offset)
      end

      def -(days : Int) : DateTime
        DateTime.new(@jd - days, @daysec, @offset)
      end

      def to_s : String
        "#{date_part}T#{time_part}#{offset_part}"
      end

      def inspect : String
        "#<DateTime: #{to_s} ((#{jd}j,#{daysec}s,0n),+#{@offset}s,#{REFORM_JD}j)>"
      end

      def to_s_full : String
        "#{Date.to_s}T#{time_part}#{offset_part}"
      end

      private def time_part : String
        Kernel.format("%02d:%02d:%02d", hour, min, sec)
      end

      private def offset_part : String
        sign = @offset < 0 ? '-' : '+'
        a = @offset.abs
        Kernel.format("%c%02d:%02d", sign, a // 3600, (a % 3600) // 60)
      end
    end
  end
end
