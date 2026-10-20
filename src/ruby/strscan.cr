# Ruby::V4::StringScanner — посимвольно-последовательный сканер strscan:
# scan (якорится на pos), scan_until, skip, check, match?, getch, peek,
# rest/post_match/pre_match, terminate/reset, matched/[].

module Ruby
  module V4
    class StringScanner
      # Ruby StringScanner::Error (unscan без матча).
      class Error < Exception
      end

      @s : String
      @pos : Int32 = 0
      @md : Regex::MatchData?

      def initialize(@s : String)
      end

      def string : String
        @s
      end

      def pos : Int32
        @pos
      end

      def pos=(v : Int)
        @pos = v.to_i32
      end

      def eos? : Bool
        @pos >= @s.bytesize
      end

      def reset : Nil
        @pos = 0
        @md = nil
      end

      def terminate : Nil
        @pos = @s.bytesize
      end

      # Матч, начинающийся ровно на pos (якорь \G). nil → сброс последнего
      # матча, как в Ruby.
      private def anchored_match(re : Regex) : Regex::MatchData?
        m = re.match(@s, @pos)
        @md = (m && m.begin(0) == @pos) ? m : nil
        @md
      end

      def scan(re : Regex) : String?
        m = anchored_match(re)
        return nil unless m
        @pos = m.end(0)
        m[0]
      end

      def scan_until(re : Regex) : String?
        m = re.match(@s, @pos)
        return nil unless m
        res = @s[@pos...m.end(0)]
        @pos = m.end(0)
        @md = m
        res
      end

      # exist?: индекс конца ближайшего матча от pos (pos не двигается).
      def exist?(re : Regex) : Int32?
        m = re.match(@s, @pos)
        m ? m.end(0) : nil
      end

      # skip_until: как scan_until, но возвращает длину съеденного.
      def skip_until(re : Regex) : Int32?
        m = re.match(@s, @pos)
        return nil unless m
        len = m.end(0) - @pos
        @pos = m.end(0)
        @md = m
        len
      end

      # unscan: откат к началу последнего успешного матча; без него — ошибка.
      def unscan : Nil
        m = @md
        raise Error.new("unscan failed: previous match had failed") unless m
        @pos = m.begin(0)
        @md = nil
      end

      def string=(s : String) : String
        @s = s
        @pos = 0
        @md = nil
        s
      end

      def skip(re : Regex) : Int32?
        m = anchored_match(re)
        return nil unless m
        @pos = m.end(0)
        m.end(0) - m.begin(0)
      end

      def check(re : Regex) : String?
        m = anchored_match(re)
        m ? m[0] : nil
      end

      def match?(re : Regex) : Int32?
        m = anchored_match(re)
        m ? m.end(0) - m.begin(0) : nil
      end

      def getch : String?
        return nil if eos?
        reader = Char::Reader.new(@s, @pos)
        ch = reader.current_char
        reader.next_char
        @pos = reader.pos
        ch.to_s
      end

      def peek(n : Int) : String
        @s.byte_slice(@pos, n)
      end

      def rest : String
        @s.byte_slice(@pos, @s.bytesize - @pos)
      end

      def matched? : Bool
        !@md.nil?
      end

      def matched : String?
        @md.try &.[0]
      end

      def [](group : Int) : String?
        @md.try &.[group]?
      end

      def [](name : String) : String?
        @md.try &.[name]?
      end

      def post_match : String?
        m = @md
        return nil unless m
        @s.byte_slice(m.end(0), @s.bytesize - m.end(0))
      end

      def pre_match : String?
        m = @md
        return nil unless m
        @s.byte_slice(0, m.begin(0))
      end

      def beginning_of_line? : Bool
        @pos == 0 || @s.byte_at(@pos - 1) == '\n'.ord
      end
    end
  end
end
