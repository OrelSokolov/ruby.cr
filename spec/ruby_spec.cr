require "./spec_helper"

describe Ruby::V4::MT19937 do
  it "воспроизводит выборки Random Ruby (seed 42)" do
    r = Ruby::V4::Random.new(42)
    r.rand.should eq(0.3745401188473625)
    4.times { r.rand }
    # после 1 float-выборки (2 слова) следующий rand(1000) оракула — см. random.txt
  end

  it "сид < 2^32 идёт через init_genrand (совпадает с numpy RandomState)" do
    Ruby::V4::Random.new(0).rand.should eq(0.5488135039273248)
    Ruby::V4::Random.new(-1).rand.should eq(Ruby::V4::Random.new(1).rand)
  end

  it "большой сид: ведущее слово 1 отбрасывается" do
    Ruby::V4::Random.new(1.to_big_i << 64).rand.should eq(0.1507172537105722)
  end

  it "bytes совпадает с Ruby" do
    Ruby::V4::Random.new(42).bytes(8).should eq([102, 220, 225, 95, 179, 61, 234, 203])
  end

  it "srand/rand глобального генератора" do
    Ruby::V4::Random.srand(99)
    Ruby::V4::Random.rand.should eq(0.6722785586307918)
  end
end

describe "Array#shuffle (Ruby-порядок)" do
  it "даёт перестановку как Ruby" do
    [1, 2, 3, 4, 5].shuffle(Ruby::V4::Random.new(42)).should eq([2, 5, 3, 1, 4])
  end
end

describe Ruby::V4::Kernel do
  it "format с именованными аргументами" do
    Ruby::V4.format("%<foo>05.1f", foo: 3.14159).should eq("003.1")
    Ruby::V4.format("%{a}-%{b}", a: 1, b: 2).should eq("1-2")
  end

  it "format %#o даёт префикс 0, а не 0o" do
    Ruby::V4.format("%#o", 8).should eq("010")
  end

  it "позиционные аргументы" do
    Ruby::V4.format("%3$s %1$s %2$s", "a", "b", "c").should eq("c a b")
  end
end

describe Ruby::V4::Time do
  it "to_s/inspect для utc и фиксированного офсета" do
    Ruby::V4::Time.gm(2026, 1, 2, 3, 4, 5).to_s.should eq("2026-01-02 03:04:05 UTC")
    Ruby::V4::Time.new(2026, 1, 2, 3, 4, 5, "+05:30").to_s.should eq("2026-01-02 03:04:05 +0530")
  end

  it "at(Float) обрезает наносекунды как Ruby" do
    t = Ruby::V4::Time.at(0.123456789)
    t.nsec.should eq(123456788)
    t.usec.should eq(123456)
  end

  it "strftime с флагами Ruby" do
    t = Ruby::V4::Time.gm(2026, 1, 2, 3, 4, 5)
    t.strftime("%-d %-m").should eq("2 1")
    t.strftime("%^A").should eq("FRIDAY")
    t.strftime("%_m").should eq(" 1")
    t.strftime("%C %y %G %V %u").should eq("20 26 2026 01 5")
    t.strftime("%+").should eq("%+")     # неизвестная директива — буквально
    t.strftime("%.3N").should eq("%.3N")
  end

  it "parse: UTC/GMT/смещение" do
    Ruby::V4::Time.parse("2026-01-02 03:04:05 UTC").to_s.should eq("2026-01-02 03:04:05 UTC")
    Ruby::V4::Time.parse("Fri, 02 Jan 2026 03:04:05 GMT").to_s.should eq("2026-01-02 03:04:05 +0000")
    Ruby::V4::Time.parse("2026-01-02T03:04:05+05:30").utc.to_s.should eq("2026-01-01 21:34:05 UTC")
  end

  it "rfc2822 у utc — -0000" do
    Ruby::V4::Time.gm(2026, 1, 2, 3, 4, 5).rfc2822.should eq("Fri, 02 Jan 2026 03:04:05 -0000")
  end
end

describe Ruby::V4::Date do
  it "jd/mjd/iso-неделя" do
    d = Ruby::V4::Date.new(2026, 1, 2)
    d.jd.should eq(2461043)
    d.mjd.should eq(61042)
    d.cweek.should eq(1)
    d.cwyear.should eq(2026)
    d.friday?.should be_true
  end

  it "григорианская реформа" do
    Ruby::V4::Date.new(1582, 10, 4).julian?.should be_true
    Ruby::V4::Date.new(1582, 10, 15).gregorian?.should be_true
  end

  it "next_month клампит день к концу месяца" do
    Ruby::V4::Date.new(2026, 1, 31).next_month.to_s.should eq("2026-02-28")
  end

  it "commercial неделя" do
    Ruby::V4::Date.commercial(2026, 1, 1).to_s.should eq("2025-12-29")
  end
end

describe Ruby::V4::DateTime do
  it "new_offset сохраняет момент" do
    Ruby::V4::DateTime.civil(2026, 1, 2, 3, 4, 5).new_offset("+05:30").to_s
      .should eq("2026-01-02T08:34:05+05:30")
  end
end

describe "core_ext" do
  it "String#succ/hex/oct" do
    "zz".succ.should eq("aaa")
    "0x10".hex.should eq(16)
    "777".oct.should eq(511)
  end

  it "Int: divmod/modulo как Ruby" do
    (-7).divmod(3).to_a.should eq([-3, 2])
    (-7).modulo(3).should eq(2)
    (-7).remainder(3).should eq(-1)
    2.pow(10, 100).should eq(24)
  end

  it "Float round по Ruby (half: :up)" do
    Ruby::V4.round(2.5).should eq(3)
    Ruby::V4.round(-2.5).should eq(-3)
    Ruby::V4.round(2.5, half: :even).should eq(2)
  end

  it "Array: filter_map/values_at/combo" do
    [1, 2, 3, 4].filter_map { |x| x.even? ? x * 10 : nil }.should eq([20, 40])
    [1, 2, 3].values_at(0..1).should eq([1, 2])
    [1, 2, 3, 4].combination(2).size.should eq(6)
  end

  it "Hash: except/slice/sum" do
    ({"a" => 1, "b" => 2}).except("a").should eq({"b" => 2})
    ({"a" => 1, "b" => 2}).slice("a").should eq({"a" => 1})
    ({"a" => 1, "b" => 2}).sum { |k, v| v }.should eq(3)
  end

  it "Set: subset?/disjoint?/add?" do
    Set{1, 2}.subset?(Set{1, 2, 3}).should be_true
    Set{1, 2}.disjoint?(Set{3}).should be_true
    s = Set{1, 2}
    Ruby::V4.set_add?(s, 1).should be_nil
    Ruby::V4.set_add?(s, 3).should_not be_nil
    s.includes?(3).should be_true
  end

  it "Range#overlap?/cover?" do
    (1..3).overlap?(3..5).should be_true
    (1..3).overlap?(4..5).should be_false
    (1..5).cover?(3).should be_true
  end
end

describe "итерация 2: random/sample" do
  it "rand(float..float) — inclusive-формула Ruby (int_pair_to_real_inclusive)" do
    r = Ruby::V4::Random.new(1)
    r.rand(1.5..3.0).should eq(2.125532998003945)
  end

  it "rand(int..float) — смешанный диапазон" do
    r = Ruby::V4::Random.new(4)
    r.rand((1)..(3.5)).should eq(3.4175745964170328)
  end

  it "Array#sample — один элемент (limited(len-1))" do
    [1, 2, 3, 4, 5].sample(Ruby::V4::Random.new(42)).should eq(4)
    [1, 2, 3, 4, 5, 6, 7, 8].sample(Ruby::V4::Random.new(7)).should eq(8)
    ([] of Int32).sample(Ruby::V4::Random.new(1)).should be_nil
  end

  it "Array#sample(n) — сжатие индексов как rb_ary_sample" do
    r = Ruby::V4::Random.new(3)
    [1, 2, 3, 4, 5].sample(2, r).should eq([3, 1])
    [1, 2, 3, 4, 5, 6, 7, 8].sample(3, Ruby::V4::Random.new(9)).should eq([7, 5, 8])
    [1, 2, 3].sample(3, Ruby::V4::Random.new(2)).should eq([1, 3, 2])
  end
end

describe "итерация 2: time/rational" do
  it "Time.at — локальное время" do
    Ruby::V4::Time.at(0).to_s.should eq("1970-01-01 03:00:00 +0300")
    Ruby::V4::Time.at(0).zone.should eq("MSK")
  end

  it "Time.at(sec, frac, unit) — inspect с дробью, to_s без" do
    Ruby::V4::Time.at(1, 500, :millisecond).inspect.should eq("1970-01-01 03:00:01.5 +0300")
    Ruby::V4::Time.at(1.5).to_s.should eq("1970-01-01 03:00:01 +0300")
  end

  it "subsec — точный Rational из битов double" do
    Ruby::V4::Time.at(0.123456789).subsec.inspect.should eq("(8895999182988127/72057594037927936)")
    Ruby::V4::Time.at(0.5).subsec.inspect.should eq("(1/2)")
  end

  it "strftime %:z/%::z и %Z зоны" do
    Ruby::V4::Time.gm(2026, 1, 2, 3, 4, 5).strftime("%:z").should eq("+00:00")
    Ruby::V4::Time.new(2026, 1, 2, 3, 4, 5, "+05:30").strftime("%:z %::z").should eq("+05:30 +05:30:00")
    # %Z локальной зоны проверяется батареей twinshot в TZ=Europe/Moscow.
  end

  it "Time.parse: дата без времени, слэш, Z, ±HHMM" do
    Ruby::V4::Time.parse("2026-01-02").to_s.should eq("2026-01-02 00:00:00 +0300")
    Ruby::V4::Time.parse("2026/01/02 03:04:05").to_s.should eq("2026-01-02 03:04:05 +0300")
    Ruby::V4::Time.parse("2026-01-02T03:04:05Z").to_s.should eq("2026-01-02 03:04:05 UTC")
    Ruby::V4::Time.parse("2026-01-02 03:04:05").utc_offset.should eq(10800)
  end
end

describe "итерация 2: date" do
  it "отрицательный год: знак отдельно от %04d" do
    Ruby::V4::Date.jd(0).to_s.should eq("-4712-01-01")
    Ruby::V4::Date.new(-1, 1, 1).to_s.should eq("-0001-01-01")
    Ruby::V4::Date.new(-1, 1, 1).inspect.should eq("#<Date: -0001-01-01 ((1720693j,0s,0n),+0s,2299161j)>")
  end

  it "parse имён месяцев" do
    Ruby::V4::Date.parse("January 2, 2026").to_s.should eq("2026-01-02")
    Ruby::V4::Date.parse("2 Jan 2026").to_s.should eq("2026-01-02")
    Ruby::V4::Date.parse("Jan 2, 2026").to_s.should eq("2026-01-02")
  end

  it "DateTime.parse iso8601-строки" do
    Ruby::V4::DateTime.parse("2026-01-02T03:04:05+05:30").to_s.should eq("2026-01-02T03:04:05+05:30")
  end
end

describe "итерация 2: core_ext/more" do
  it "String#casecmp/casecmp?" do
    "abc".casecmp("ABC").should eq(0)
    "abc".casecmp("abd").should eq(-1)
    "abc".casecmp?("ABC").should be_true
    "abc".casecmp?("abd").should be_false
  end

  it "String#upto с exclusivity" do
    "a9".upto("b1").should eq(["a9", "b0", "b1"])
    "aa".upto("ac", true).should eq(["aa", "ab"])
  end

  it "Int#allbits?/anybits?/nobits?" do
    255.allbits?(0b101).should be_true
    5.anybits?(2).should be_false
    5.nobits?(2).should be_true
  end

  it "Int#then" do
    5.then { |x| x + 1 }.should eq(6)
  end

  it "Enumerable#grep/grep_v с блоком" do
    [1, 2, 3, 4].grep(2).should eq([2])
    ["a", 1, "b", 2].grep(String).should eq(["a", "b"])
    [1, 2, 3, 4].grep(2..3).should eq([2, 3])
    [1, 2, 3, 4].grep_v(2..3).should eq([1, 4])
    [1, 2, 3, 4].grep(2) { |x| x * 10 }.should eq([20])
  end

  it "Hash#transform_keys(Hash)" do
    h = {"a" => 1, "b" => 2}
    h.transform_keys({"a" => "z", "b" => "y"}).should eq({"z" => 1, "y" => 2})
  end

  it "Ruby::V4.lines с chomp" do
    Ruby::V4.lines("hello world", chomp: true).should eq(["hello world"])
    Ruby::V4.lines("a\nb").should eq(["a\n", "b"])
  end
end

describe "итерация 2: pack/unpack" do
  it "целочисленные директивы round-trip" do
    [1, 2].pack("C*").unpack("C*").should eq([1, 2])
    [50000].pack("V").unpack("V").should eq([50000])
    [-1].pack("l").unpack("l").should eq([-1])
    [(1_i64 << 40)].pack("Q>").unpack("Q>").should eq([1_i64 << 40])
    [-(1_i64 << 40)].pack("q<").unpack("q<").should eq([-(1_i64 << 40)])
  end

  it "байтовый порядок N/V" do
    [1048576].pack("N").bytes.should eq([0, 16, 0, 0])
    [1048576].pack("V").bytes.should eq([0, 0, 16, 0])
  end

  it "hex H/h" do
    "AB".unpack("H*").should eq(["4142"])
    "AB".unpack("h*").should eq(["1424"])
    ["4142"].pack("H*").should eq("AB")
  end

  it "base64 m/m0" do
    ["hello"].pack("m").should eq("aGVsbG8=\n")
    ["hello"].pack("m0").should eq("aGVsbG8=")
    "aGVsbG8=\n".unpack("m").should eq(["hello"])
  end

  it "U/w/A" do
    [233].pack("U").should eq("é")
    [65].pack("w").bytes.should eq([65])
    ["abc"].pack("A6").should eq("abc   ")
    ["ab", "cd"].pack("A2A3").bytes.should eq([97, 98, 99, 100, 32])
  end

  it "float директивы" do
    [1.5].pack("e").unpack("e").should eq([1.5])
    [1.5].pack("f").unpack("f").should eq([1.5])
    [0.5].pack("d").unpack("d").should eq([0.5])
    [0.5].pack("E").unpack("E").should eq([0.5])
  end

  it "unpack1" do
    [1, 2].pack("C*").unpack1("C").should eq(1)
  end
end

describe "итерация 2: StringScanner" do
  it "scan якорится на pos" do
    s = Ruby::V4::StringScanner.new("key = value")
    s.scan(/\w+/).should eq("key")
    s.scan(/\s*=\s*/).should eq(" = ")
    s.scan(/\w+/).should eq("value")
    s.scan(/\w+/).should be_nil
  end

  it "группы, pos, eos?" do
    s = Ruby::V4::StringScanner.new("123abc")
    s.scan(/(\d+)(\w+)/).should eq("123abc")
    s[1].should eq("123")
    s[2].should eq("abc")
    s.matched.should eq("123abc")
    s.pos.should eq(6)
    s.eos?.should be_true
  end

  it "scan_until/skip/check/match?" do
    Ruby::V4::StringScanner.new("hello world").scan_until(/o/).should eq("hello")
    Ruby::V4::StringScanner.new("  abc").tap { |s| s.skip(/\s+/) }.pos.should eq(2)
    Ruby::V4::StringScanner.new("abc").check(/\w+/).should eq("abc")
    Ruby::V4::StringScanner.new("abc").match?(/b/).should be_nil
    Ruby::V4::StringScanner.new("abc").match?(/a/).should eq(1)
  end

  it "rest/pre_match/post_match/сброс состояния при неудаче" do
    s = Ruby::V4::StringScanner.new("abc")
    s.scan(/a/)
    s.rest.should eq("bc")
    s.post_match.should eq("bc")
    s.pre_match.should eq("")
    s.scan(/z/).should be_nil
    s.matched?.should be_false
  end

  it "getch/peek/string/beginning_of_line?" do
    Ruby::V4::StringScanner.new("abc").getch.should eq("a")
    Ruby::V4::StringScanner.new("abcdef").peek(2).should eq("ab")
    Ruby::V4::StringScanner.new("abc").string.should eq("abc")
    s = Ruby::V4::StringScanner.new("ab")
    s.beginning_of_line?.should be_true
    s.scan(/a/)
    s.beginning_of_line?.should be_false
  end
end

describe "итерация 2: base64/securerandom" do
  it "encode64 переносит строки по 60" do
    Ruby::V4::Base64.encode64("hello").should eq("aGVsbG8=\n")
    Ruby::V4::Base64.strict_encode64("a" * 80).should_not contain("\n")
    Ruby::V4::Base64.encode64("a" * 80).includes?("\n").should be_true
    Ruby::V4::Base64.decode64("aGVsbG8=").should eq("hello")
    Ruby::V4::Base64.urlsafe_decode64("YWJj").should eq("abc")
  end

  it "SecureRandom размеры/форматы" do
    Ruby::V4::SecureRandom.hex(8).size.should eq(16)
    Ruby::V4::SecureRandom.base64(12).size.should eq(16)
    Ruby::V4::SecureRandom.urlsafe_base64(8).size.should eq(11)
    Ruby::V4::SecureRandom.random_bytes(4).bytesize.should eq(4)
    x = Ruby::V4::SecureRandom.random_number(10)
    (x >= 0 && x < 10).should be_true
    Ruby::V4::SecureRandom.alphanumeric(12).size.should eq(12)
  end
end

describe "итерация 3: pack-расширения" do
  it "Z — NUL-терминатор, усечение без терминатора" do
    ["ab"].pack("Z3").bytes.should eq([97, 98, 0])
    ["ab", "cd"].pack("Z3Z3").bytes.should eq([97, 98, 0, 99, 100, 0])
    "a\0bc".unpack("Z*").should eq(["a"])
  end

  it "x/X/@ — паддинг, откат, абсолютная позиция" do
    [1, 2].pack("CxC").bytes.should eq([1, 0, 2])
    [1, 2].pack("Cx3C").bytes.should eq([1, 0, 0, 0, 2])
    [1, 2, 3].pack("CCXC").bytes.should eq([1, 3])
    [1, 2, 3].pack("C@3C").bytes.should eq([1, 0, 0, 2])
  end

  it "B/b — битовые строки" do
    ["101"].pack("B*").bytes.should eq([160])
    ["101"].pack("b*").bytes.should eq([5])
    String.new(Bytes[0xA0]).unpack("B8").should eq(["10100000"])
    String.new(Bytes[0xA0]).unpack("b8").should eq(["00000101"])
  end

  it "M (quoted-printable) и u (uuencode)" do
    ["hello"].pack("M").should eq("hello=\n")
    ["hello"].pack("u").should eq("%:&5L;&\\`\n")
  end

  it "count ограничивает unpack" do
    [1, 2, 3].pack("C*").unpack("C2").should eq([1, 2])
    [1, 2].pack("S<").unpack("S<").should eq([1])
  end
end

describe "итерация 3: strscan-расширения" do
  it "exist?/skip_until" do
    s = Ruby::V4::StringScanner.new("test string")
    s.exist?(/s/).should eq(3)
    s.pos.should eq(0)
    s.skip_until(/str/).should eq(8)
  end

  it "unscan откатывает и бросает Error без матча" do
    s = Ruby::V4::StringScanner.new("abc")
    s.scan(/a/)
    s.unscan
    s.pos.should eq(0)
    expect_raises(Ruby::V4::StringScanner::Error) do
      Ruby::V4::StringScanner.new("abc").tap { |x| x.scan(/z/) }.unscan
    end
  end

  it "string= сбрасывает состояние" do
    s = Ruby::V4::StringScanner.new("abc")
    s.string = "xyz"
    s.scan(/x/).should eq("x")
  end

  it "[] по именованным группам" do
    s = Ruby::V4::StringScanner.new("abcd")
    s.scan(/(?<first>\w)(?<second>\w)/)
    s["first"].should eq("a")
    s["second"].should eq("b")
  end

  it "peek за концом и matched после неудачи" do
    Ruby::V4::StringScanner.new("abc").peek(99).should eq("abc")
    s = Ruby::V4::StringScanner.new("abc")
    s.scan(/a/)
    s.scan(/a/)
    s.matched.should be_nil
  end
end

describe "итерация 3: Time#round/ceil" do
  it "round с точностью и переносом в секунду" do
    Ruby::V4::Time.at(0.123456789).round(3).nsec.should eq(123000000)
    Ruby::V4::Time.at(0.999999999).round(3).nsec.should eq(0)
    Ruby::V4::Time.at(1.5).round.to_i.should eq(2)
  end

  it "ceil с переносом" do
    Ruby::V4::Time.at(0.123456789).ceil(3).nsec.should eq(124000000)
    Ruby::V4::Time.at(0.999999999).ceil(3).sec.should eq(1)
  end
end

describe "итерация 3: Date strptime/parse" do
  it "strptime" do
    Ruby::V4::Date.strptime("2026-01-02", "%Y-%m-%d").to_s.should eq("2026-01-02")
    Ruby::V4::Date.strptime("02/01/2026", "%d/%m/%Y").to_s.should eq("2026-01-02")
    Ruby::V4::Date.strptime("20260102", "%Y%m%d").to_s.should eq("2026-01-02")
  end

  it "parse ISO basic и ISO week" do
    Ruby::V4::Date.parse("20260102").to_s.should eq("2026-01-02")
    Ruby::V4::Date.parse("2026-W01-1").to_s.should eq("2025-12-29")
  end

  it "prev_year/next_year клампят 29 февраля" do
    Ruby::V4::Date.new(2024, 2, 29).prev_year.to_s.should eq("2023-02-28")
    Ruby::V4::Date.new(2024, 2, 29).next_year.to_s.should eq("2025-02-28")
  end
end

describe "итерация 3: kernel-функции" do
  it "integer/float — строгий парсинг" do
    Ruby::V4.integer("42").should eq(42)
    Ruby::V4.integer("0x1A", 16).should eq(26)
    Ruby::V4.integer("1_000").should eq(1000)
    expect_raises(ArgumentError) { Ruby::V4.integer("abc") }
    Ruby::V4.float("3.14").should eq(3.14)
    Ruby::V4.float("1e3").should eq(1000.0)
    expect_raises(ArgumentError) { Ruby::V4.float("x") }
  end

  it "rational/array/hash_of" do
    Ruby::V4.rational(3, 6).inspect.should eq("(1/2)")
    Ruby::V4.rational(4).inspect.should eq("(4/1)")
    Ruby::V4.array(nil).should eq([] of Nil)
    Ruby::V4.array([1, 2]).should eq([1, 2])
    Ruby::V4.array(1..3).should eq([1, 2, 3])
    Ruby::V4.array("ab").should eq(["ab"])
    Ruby::V4.hash_of([[1, 2]]).should eq({1 => 2})
  end

  it "catch/throw" do
    result = Ruby::V4.catch(:done) do |tag|
      [1, 2, 3].each do |x|
        Ruby::V4.throw(:done, x * 10) if x > 1
      end
      nil
    end
    result.should eq(20)
  end
end

describe "итерация 5" do
  it "sub/gsub с блоком (строка) и Hash" do
    Ruby::V4.gsub("hello", "l") { |m| m.upcase }.should eq("heLLo")
    Ruby::V4.sub("hello", /l/) { |m| m + "!" }.should eq("hel!lo")
    Ruby::V4.gsub("hello", /l/, {"l" => "L"}).should eq("heLLo")
    # отсутствующий ключ → пустая строка
    Ruby::V4.gsub("a1b2", /\d/, {"1" => "one"}).should eq("aoneb")
  end

  it "round с отрицательной точностью (half-up)" do
    Ruby::V4.round(123, -1).should eq(120)
    Ruby::V4.round(125, -1).should eq(130)
    Ruby::V4.round(-125, -1).should eq(-130)
    Ruby::V4.round(1234, -2).should eq(1200)
    Ruby::V4.round(12345, -3).should eq(12000)
  end

  it "ceil/floor/truncate с отрицательной точностью" do
    15.ceil(-1).should eq(20)
    14.floor(-1).should eq(10)
    15.truncate(-1).should eq(10)
  end

  it "Date >>/<<" do
    (Ruby::V4::Date.new(2026, 1, 2) >> 1).to_s.should eq("2026-02-02")
    (Ruby::V4::Date.new(2026, 1, 31) >> 1).to_s.should eq("2026-02-28")
    (Ruby::V4::Date.new(2026, 3, 31) << 1).to_s.should eq("2026-02-28")
    (Ruby::V4::Date.new(2026, 1, 2) >> 12).to_s.should eq("2027-01-02")
  end

  it "Time.parse rfc2822 с числовым офсетом" do
    Ruby::V4::Time.parse("Fri, 02 Jan 2026 03:04:05 +0300").to_s.should eq("2026-01-02 03:04:05 +0300")
    Ruby::V4::Time.parse("Fri, 02 Jan 2026 03:04:05 -0500").utc_offset.should eq(-18000)
    Ruby::V4::Time.parse("Fri, 02 Jan 2026 03:04:05 +0000").to_s.should eq("2026-01-02 03:04:05 +0000")
  end

  it "File.basename/extname/join/split/expand_path совместимы" do
    File.basename("/a/b/c.txt", ".txt").should eq("c")
    File.basename("/a/b/").should eq("b")
    File.extname("/a/b/.profile").should eq("")
    File.join("a/", "b").should eq("a/b")
    File.split("/a/b/c.txt").should eq({"/a/b", "c.txt"})
    File.expand_path("../b", "/a/c").should eq("/a/b")
  end

  it "String#[] с regex и группой (Int/Symbol), nil без матча" do
    "2026-01-02"[/(?<y>\d+)-(?<m>\d+)/, :m].should eq("01")
    "ab"[/(a)(b)/, 1].should eq("a")
    "ab"[/(a)(b)/, 2].should eq("b")
    "ab"[/z/, 1].should be_nil
  end

  it "Regexp.union экранирует части" do
    (!Regex.union("a+", "b").match("a+").nil?).should be_true
    Regex.union("a+", "b").match("a").should be_nil
  end

  it "сообщения ошибок в Ruby-формате" do
    msg = begin
      {"a" => 1}.fetch("z")
      "no"
    rescue e : KeyError
      e.message
    end
    msg.should eq(%(key not found: "z"))
    msg2 = begin
      [1, 2, 3].fetch(9)
      "no"
    rescue e : IndexError
      e.message
    end
    msg2.should eq("index 9 outside of array bounds: -3...3")
  end
end

describe "итерация 4: частотное ядро" do
  it "String#match?/=~/slice(Range)/start_with?(Regex)" do
    "hello".match?(/ll/).should be_true
    "hello".match?(/xx/).should be_false
    ("hello" =~ /ll/).should eq(2)
    "hello".slice(1..3).should eq("ell")
    "Hello".start_with?(/He/).should be_true
    "Hello".start_with?(/xx/).should be_false
  end

  it "String#count с наборами и диапазонами" do
    "hello".count("l").should eq(2)
    "hello world".count("lo").should eq(5)
    "abcdef".count("a-c").should eq(3)
  end

  it "split с limit" do
    "a,b,c".split(",", 2).should eq(["a", "b,c"])
    "a,b,c".split(/,/, 2).should eq(["a", "b,c"])
  end

  it "each_line(chomp:)" do
    Ruby::V4.lines("a\nb\nc", chomp: true).should eq(["a", "b", "c"])
    Ruby::V4.lines("a\nb", chomp: true).should eq(["a", "b"])
  end

  it "Array set-операции и append/prepend/slice(Range)" do
    [1, 2, 3].intersection([2, 3, 4]).should eq([2, 3])
    [1, 2, 3].union([3, 4], [4, 5]).should eq([1, 2, 3, 4, 5])
    [1, 2, 3].difference([2]).should eq([1, 3])
    a = [1, 2]
    a.append(3).should eq([1, 2, 3])
    b = [1, 2]
    b.prepend(0).should eq([0, 1, 2])
    ["a", "b", "c", "d"].slice(1..2).should eq(["b", "c"])
  end

  it "Hash merge!/filter/find_index/each_key" do
    h = {"a" => 1}
    h.merge!({"b" => 2}).should eq({"a" => 1, "b" => 2})
    ({"a" => 1, "b" => 2}.filter { |k, v| v > 1 }).should eq({"b" => 2})
    ({"a" => 1, "b" => 2}.find_index { |k, v| v > 1 }).should eq(1)
    ({"a" => 1, "b" => 2}.each_key.to_a).should eq(["a", "b"])
  end

  it "Time↔Date↔DateTime мосты" do
    Ruby::V4::Time.utc(2026, 1, 2, 3, 4, 5).to_date.to_s.should eq("2026-01-02")
    Ruby::V4::Time.utc(2026, 1, 2, 3, 4, 5).to_datetime.to_s.should eq("2026-01-02T03:04:05+00:00")
    Ruby::V4::Time.local(2026, 1, 2, 3, 4, 5).to_datetime.to_s.should eq("2026-01-02T03:04:05+03:00")
    Ruby::V4::Date.new(2026, 1, 2).to_datetime.to_s.should eq("2026-01-02T00:00:00+00:00")
    Ruby::V4::DateTime.civil(2026, 1, 2, 3, 4, 5).to_date.to_s.should eq("2026-01-02")
  end

  it "rescue-семантика ошибок (деление/fetch/raise)" do
    z = 0
    result = begin
      1 // z
      "no"
    rescue
      "rescued"
    end
    result.should eq("rescued")
    r = begin
      {"a" => 1}.fetch("z")
      "no"
    rescue e : KeyError
      "ke"
    end
    r.should eq("ke")
  end

  it "nil.to_a/to_h, clamp(Range), dup" do
    nil.to_a.should eq([] of Nil)
    nil.to_h.should eq({} of Nil => Nil)
    5.clamp(2..4).should eq(4)
    "a".dup.should eq("a")
  end
end

describe "итерация 6: unpack M/u, исключения, мосты, strptime" do
  it "pack(\"M\") — quoted-printable с переносом по 72/73 и сырыми \\n/\\t" do
    ["hello world"].pack("M").should eq("hello world=\n")
    ["=ab"].pack("M").should eq("=3Dab=\n")
    ["a" * 100].pack("M").size.should eq(104)
    ["a\nb"].pack("M").should eq("a\nb=\n")
    ["\t"].pack("M").should eq("\t=\n")
    ["\x7F"].pack("M").should eq("=7F=\n")
  end

  it "unpack(\"M\") — =XX, мягкий перенос, одиночный '='" do
    ["hello"].pack("M").unpack("M").should eq(["hello"])
    (["a" * 100].pack("M").unpack("M") == ["a" * 100]).should be_true
    "=48=69".unpack("M").should eq(["Hi"])
    "a=\nb".unpack1("M").should eq("ab")
    "x=Z".unpack1("M").should eq("x=Z")
  end

  it "unpack(\"u\") — uudecode" do
    "#86)C".unpack("u").should eq(["abc"])
    "#<V)S".unpack("u").should eq(["sbs"])
    ["hello world !"].pack("u").unpack("u").should eq(["hello world !"])
    [String.new(Bytes[0xFF, 0x00, 0xFE])].pack("u").unpack("u").should eq([String.new(Bytes[0xFF, 0x00, 0xFE])])
  end

  it "исключения: ZeroDivisionError/StopIteration/FrozenError" do
    z = 0
    r = begin
      1 // z
      "no"
    rescue ZeroDivisionError
      "zd"
    end
    r.should eq("zd")
    s = begin
      raise StopIteration.new
      "no"
    rescue StopIteration
      "si"
    end
    s.should eq("si")
    f = begin
      raise FrozenError.new
      "no"
    rescue FrozenError
      "fe"
    end
    f.should eq("fe")
  end

  it "Date#to_time / DateTime#to_time (офсет сохраняется)" do
    Ruby::V4::DateTime.parse("2026-01-02T03:04:05+05:00").to_time.to_s.should eq("2026-01-02 03:04:05 +0500")
    Ruby::V4::DateTime.parse("2026-01-02T03:04:05+05:00").to_time.utc_offset.should eq(18000)
  end

  it "Time.strptime — локальное время, одинарные цифры" do
    Ruby::V4::Time.strptime("2026-01-02 03:04:05", "%Y-%m-%d %H:%M:%S").to_s.should eq("2026-01-02 03:04:05 +0300")
    Ruby::V4::Time.strptime("02/01/2026 7:08:09", "%d/%m/%Y %H:%M:%S").to_s.should eq("2026-01-02 07:08:09 +0300")
    Ruby::V4::Time.strptime("2026-01-02", "%Y-%m-%d").to_s.should eq("2026-01-02 00:00:00 +0300")
  end
end
