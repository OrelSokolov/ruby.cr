# Зеркальные слепки stdlib через ruby.cr (Ruby::V4 / переоткрытия).
# Читает общий список кейсов record/cases.txt и для каждого выражения
# печатает "выражение => результат" — метка в метку с oracle/record.rb.
#
# Запуск из корня: crystal run record/record.cr -- artifacts/crystal-v4 v4

require "../src/ruby"
require "big"

OUT = ARGV[0]? || abort("usage: record.cr DIR [v3|v4]")
VER = ARGV[1]? || "v4"

def ri(x) : String
  VER == "v3" ? Ruby::V3.inspect(x) : Ruby::V4.inspect(x)
end

HANDLERS = {} of String => Array(Proc(String))

# Дублирующиеся метки (s.scan(/\w+/), s.pos) снимаются последовательно —
# как eval оракула: каждый snap добавляется в очередь своей метки.
def snap(label : String, &block : -> String) : Nil
  (HANDLERS[label] ||= [] of Proc(String)) << block
end

T = Ruby::V4::Time
D = Ruby::V4::Date
DT = Ruby::V4::DateTime
R = Ruby::V4::Random

Ruby.struct_def Point, x, y
Ruby.struct_def KwPoint, a, b, keyword_init: true

# ---------------------------------------------------------------- kernel
snap("format(\"%d\", 42)") { ri(Ruby::V4.format("%d", 42)) }
snap("format(\"%5d|\", 42)") { ri(Ruby::V4.format("%5d|", 42)) }
snap("format(\"%-5d|\", 42)") { ri(Ruby::V4.format("%-5d|", 42)) }
snap("format(\"%05d\", -42)") { ri(Ruby::V4.format("%05d", -42)) }
snap("format(\"%+d\", 42)") { ri(Ruby::V4.format("%+d", 42)) }
snap("format(\"%+d\", -42)") { ri(Ruby::V4.format("%+d", -42)) }
snap("format(\"% d\", 42)") { ri(Ruby::V4.format("% d", 42)) }
snap("format(\"%x\", 255)") { ri(Ruby::V4.format("%x", 255)) }
snap("format(\"%X\", 255)") { ri(Ruby::V4.format("%X", 255)) }
snap("format(\"%#x\", 255)") { ri(Ruby::V4.format("%#x", 255)) }
snap("format(\"%#X\", 255)") { ri(Ruby::V4.format("%#X", 255)) }
snap("format(\"%08x\", 255)") { ri(Ruby::V4.format("%08x", 255)) }
snap("format(\"%o\", 8)") { ri(Ruby::V4.format("%o", 8)) }
snap("format(\"%#o\", 8)") { ri(Ruby::V4.format("%#o", 8)) }
snap("format(\"%b\", 5)") { ri(Ruby::V4.format("%b", 5)) }
snap("format(\"%#b\", 5)") { ri(Ruby::V4.format("%#b", 5)) }
snap("format(\"%s|\", \"hi\")") { ri(Ruby::V4.format("%s|", "hi")) }
snap("format(\"%10s|\", \"hi\")") { ri(Ruby::V4.format("%10s|", "hi")) }
snap("format(\"%-10s|\", \"hi\")") { ri(Ruby::V4.format("%-10s|", "hi")) }
snap("format(\"%.2s|\", \"hello\")") { ri(Ruby::V4.format("%.2s|", "hello")) }
snap("format(\"%p\", \"hi\")") { ri(Ruby::V4.format("%p", "hi")) }
snap("format(\"%c\", 65)") { ri(Ruby::V4.format("%c", 65)) }
snap("format(\"%c\", \"A\")") { ri(Ruby::V4.format("%c", "A")) }
snap("format(\"100%%\")") { ri(Ruby::V4.format("100%%")) }
snap("format(\"%e\", 12345.678)") { ri(Ruby::V4.format("%e", 12345.678)) }
snap("format(\"%E\", 12345.678)") { ri(Ruby::V4.format("%E", 12345.678)) }
snap("format(\"%.2e\", 12345.678)") { ri(Ruby::V4.format("%.2e", 12345.678)) }
snap("format(\"%15.2e|\", 1.5)") { ri(Ruby::V4.format("%15.2e|", 1.5)) }
snap("format(\"%f\", 3.14159)") { ri(Ruby::V4.format("%f", 3.14159)) }
snap("format(\"%.0f\", 2.5)") { ri(Ruby::V4.format("%.0f", 2.5)) }
snap("format(\"%.0f\", 3.5)") { ri(Ruby::V4.format("%.0f", 3.5)) }
snap("format(\"%.0f\", -2.5)") { ri(Ruby::V4.format("%.0f", -2.5)) }
snap("format(\"%10.3f|\", -3.14159)") { ri(Ruby::V4.format("%10.3f|", -3.14159)) }
snap("format(\"%010.3f\", -3.14159)") { ri(Ruby::V4.format("%010.3f", -3.14159)) }
snap("format(\"%-10.2f|\", 3.14159)") { ri(Ruby::V4.format("%-10.2f|", 3.14159)) }
snap("format(\"%g\", 123456789.0)") { ri(Ruby::V4.format("%g", 123456789.0)) }
snap("format(\"%g\", 1234567890.0)") { ri(Ruby::V4.format("%g", 1234567890.0)) }
snap("format(\"%g\", 0.00012)") { ri(Ruby::V4.format("%g", 0.00012)) }
snap("format(\"%g\", 0.000012)") { ri(Ruby::V4.format("%g", 0.000012)) }
snap("format(\"%.3g\", 3.14159)") { ri(Ruby::V4.format("%.3g", 3.14159)) }
snap("format(\"%3$s %1$s %2$s\", \"a\", \"b\", \"c\")") { ri(Ruby::V4.format("%3$s %1$s %2$s", "a", "b", "c")) }
snap("format(\"%2$c\", 66, 65)") { ri(Ruby::V4.format("%2$c", 66, 65)) }
snap("format(\"%<foo>05.1f\", foo: 3.14159)") { ri(Ruby::V4.format("%<foo>05.1f", foo: 3.14159)) }
snap("format(\"%{a}-%{b}\", a: 1, b: 2)") { ri(Ruby::V4.format("%{a}-%{b}", a: 1, b: 2)) }
snap("\"%05.2f\" % [3.14159]") { ri("%05.2f" % [3.14159]) }
snap("\"%s-%s\" % [\"a\", \"b\"]") { ri("%s-%s" % ["a", "b"]) }
snap("\"%d\" % 42") { ri("%d" % 42) }

# ---------------------------------------------------------------- string
snap("\"HELLO\".downcase") { ri("HELLO".downcase) }
snap("\"hello\".upcase") { ri("hello".upcase) }
snap("\"hello WORLD\".swapcase") { ri("hello WORLD".swapcase) }
snap("\"hello world\".capitalize") { ri("hello world".capitalize) }
snap("\"hello world\".split(\" \")") { ri("hello world".split(" ")) }
snap("\"hello world\".split") { ri("hello world".split(" ")) }
snap("\"hello\".split(\"l\")") { ri("hello".split("l")) }
snap("\"a,b;;c\".split(\",\")") { ri("a,b;;c".split(",")) }
snap("\"a,b;;c\".split(/,+/)") { ri("a,b;;c".split(/,+/)) }
snap("\"hello\".sub(\"l\", \"L\")") { ri("hello".sub("l", "L")) }
snap("\"hello\".gsub(\"l\", \"L\")") { ri("hello".gsub("l", "L")) }
snap("\"hello world\".tr(\"lo\", \"01\")") { ri("hello world".tr("lo", "01")) }
snap("\"a-c\".tr(\"a-c\", \"x-z\")") { ri("a-c".tr("a-c", "x-z")) }
snap("\"hello\".squeeze") { ri("hello".squeeze) }
snap("\"hello\".squeeze(\"l\")") { ri("hello".squeeze("l")) }
snap("\"hello world\".delete(\"l\")") { ri("hello world".delete("l")) }
snap("\"  hi  \".strip") { ri("  hi  ".strip) }
snap("\"  hi  \".lstrip") { ri("  hi  ".lstrip) }
snap("\"hi  \".rstrip") { ri("hi  ".rstrip) }
snap("\"hello\".center(11, \"*\")") { ri("hello".center(11, "*")) }
snap("\"hi\".ljust(5, \".\")") { ri("hi".ljust(5, ".")) }
snap("\"hi\".rjust(5, \".\")") { ri("hi".rjust(5, ".")) }
snap("\"hello\".chars") { ri("hello".chars) }
snap("\"hello\".bytes") { ri("hello".bytes) }
snap("\"hello\".ord") { ri("hello".ord) }
snap("\"A\".ord") { ri("A".ord) }
snap("\"hello\".getbyte(0)") { ri("hello".getbyte(0)) }
snap("\"hello\".getbyte(99)") { ri("hello".getbyte(99)) }
snap("\"hello\".byteslice(1, 3)") { ri("hello".byteslice(1, 3)) }
snap("\"hello\".start_with?(\"he\", \"xx\")") { ri("hello".start_with?("he", "xx")) }
snap("\"hello\".start_with?(\"xx\", \"he\")") { ri("hello".start_with?("xx", "he")) }
snap("\"hello\".end_with?(\"lo\")") { ri("hello".end_with?("lo")) }
snap("\"hello\".end_with?(\"lx\", \"lo\")") { ri("hello".end_with?("lx", "lo")) }
snap("\"abc\"[1]") { ri("abc"[1]?.to_s) }
snap("\"abc\"[0, 2]") { ri("abc"[0, 2]) }
snap("\"abc\"[1..]") { ri("abc"[1..]) }
snap("\"abc\".slice(1, 2)") { ri("abc".slice(1, 2)) }
snap("\"abc\".index(\"b\")") { ri("abc".index("b")) }
snap("\"abc\".rindex(\"c\")") { ri("abc".rindex("c")) }
snap("\"abc\".empty?") { ri("abc".empty?) }
snap("\"\".empty?") { ri("".empty?) }
snap("\"abc\".include?(\"b\")") { ri("abc".includes?("b")) }
snap("\"abc\".reverse") { ri("abc".reverse) }
snap("\"abc\".length") { ri("abc".size) }
snap("\"abc\".size") { ri("abc".size) }
snap("\"hello\" * 2") { ri("hello" * 2) }
snap("\"01\".to_i") { ri("01".to_i) }
snap("\"ff\".to_i(16)") { ri("ff".to_i(16)) }
snap("\"3.14\".to_f") { Ruby::V4.float_to_s("3.14".to_f) }
snap("\"ff\".hex") { ri("ff".hex) }
snap("\"0x10\".hex") { ri("0x10".hex) }
snap("\"-f\".hex") { ri("-f".hex) }
snap("\"zz\".hex") { ri("zz".hex) }
snap("\"777\".oct") { ri("777".oct) }
snap("\"0x10\".oct") { ri("0x10".oct) }
snap("\"%s!\" % \"hi\"") { ri("%s!" % "hi") }
snap("\"abc\".inspect") { ri("abc".inspect) }
snap("\"a\\tb\\\"c\".inspect") { ri("a\tb\"c".inspect) }
snap("\"a\\nb\".inspect") { ri("a\nb".inspect) }
snap("\"é\".size") { ri("é".size) }
snap("\"é\".bytes.size") { ri("é".bytes.size) }
snap("\"é\".chars") { ri("é".chars) }
snap("\"hello world\".scan(/\\w+/)") { ri(Ruby::V4.scan("hello world", /\w+/)) }
snap("\"hello\".partition(\"l\")") { ri("hello".partition("l").to_a) }
snap("\"hello\".rpartition(\"l\")") { ri("hello".rpartition("l").to_a) }
snap("\"a\\nb\".lines") { ri(Ruby::V4.lines("a\nb")) }
snap("\"a\\nb\".chomp") { ri("a\nb".chomp) }
snap("\"a\\r\\n\".chomp") { ri("a\r\n".chomp) }
snap("\"a \".chomp") { ri("a ".chomp) }
snap("\"abc\".concat(\"def\")") { s = "abc"; ri(s.concat("def")) }
snap("\"abc\".prepend(\"x\")") { s = "abc"; ri(s.prepend("x")) }
snap("\"abc\".insert(1, \"X\")") { ri("abc".insert(1, "X")) }
snap("\"abc\".delete_prefix(\"ab\")") { ri("abc".delete_prefix("ab")) }
snap("\"abc\".delete_suffix(\"bc\")") { ri("abc".delete_suffix("bc")) }
snap("\"hello world\".each_char.first(3)") { ri("hello world".chars.first(3)) }
snap("\"abc\".succ") { ri("abc".succ) }
snap("\"az\".succ") { ri("az".succ) }
snap("\"zz\".succ") { ri("zz".succ) }
snap("\"a9\".succ") { ri("a9".succ) }
snap("\"Zz\".succ") { ri("Zz".succ) }
snap("\"9\".succ") { ri("9".succ) }
snap("\"abc\" <=> \"abd\"") { ri("abc" <=> "abd") }
snap("\"abc\" == \"abc\"") { ri("abc" == "abc") }

# ---------------------------------------------------------------- integer
snap("7.divmod(3)") { ri(7.divmod(3).to_a) }
snap("-7.divmod(3)") { ri((-7).divmod(3).to_a) }
snap("7.modulo(3)") { ri(7.modulo(3)) }
snap("-7.modulo(3)") { ri((-7).modulo(3)) }
snap("7.remainder(3)") { ri(7.remainder(3)) }
snap("-7.remainder(3)") { ri((-7).remainder(3)) }
snap("-7 % 3") { ri(-7 % 3) }
snap("7.fdiv(2)") { Ruby::V4.float_to_s(7.fdiv(2)) }
snap("12345.digits") { ri(12345.digits) }
snap("(2**20).digits") { ri((2 ** 20).digits) }
snap("12345.to_s(2)") { ri(12345.to_s(2)) }
snap("12345.to_s(16)") { ri(12345.to_s(16)) }
snap("12345.to_s(8)") { ri(12345.to_s(8)) }
snap("12345.to_s(36)") { ri(12345.to_s(36)) }
snap("255.bit_length") { ri(255.bit_length) }
snap("0.bit_length") { ri(0.bit_length) }
snap("(-1).bit_length") { ri((-1).bit_length) }
snap("2.pow(10)") { ri(2.pow(10)) }
snap("2.pow(10, 100)") { ri(2.pow(10, 100)) }
snap("6.gcd(4)") { ri(6.gcd(4)) }
snap("6.lcm(4)") { ri(6.lcm(4)) }
snap("2.gcdlcm(3)") { ri(2.gcdlcm(3).to_a) }
snap("10.times.to_a") { ri((0...10).to_a) }
snap("3.upto(6).to_a") { ri(3.upto(6).to_a) }
snap("6.downto(3).to_a") { ri(6.downto(3).to_a) }
snap("2.step(10, 3).to_a") { ri(2.step(to: 10, by: 3).to_a) }
snap("5.clamp(1, 3)") { ri(5.clamp(1, 3)) }
snap("7.clamp(1..3)") { ri(7.clamp(1..3)) }
snap("3.between?(1, 5)") { ri(3.between?(1, 5)) }
snap("10.pred") { ri(10.pred) }
snap("10.succ") { ri(10.succ) }
snap("10.next") { ri(10.succ) }
snap("10.chr") { ri(Ruby::V4.chr(10)) }
snap("65.chr") { ri(Ruby::V4.chr(65)) }
snap("-5.abs") { ri((-5).abs) }
snap("5.zero?") { ri(5.zero?) }
snap("0.zero?") { ri(0.zero?) }
snap("5.positive?") { ri(5.positive?) }
snap("-5.negative?") { ri((-5).negative?) }
snap("7.even?") { ri(7.even?) }
snap("7.odd?") { ri(7.odd?) }
snap("255[0]") { ri(255[0]) }
snap("255[1]") { ri(255[1]) }
snap("4[2]") { ri(4[2]) }
snap("2**10") { ri(2 ** 10) }
snap("(2**100).to_s") { ri((2.to_big_i ** 100).to_s) }
snap("(2**100).bit_length") { ri((2.to_big_i ** 100).bit_length) }
snap("(2**20).to_s(16)") { ri((2 ** 20).to_s(16)) }

# ---------------------------------------------------------------- float
snap("3.14.to_i") { ri(3.14.to_i) }
snap("-3.14.to_i") { ri((-3.14).to_i) }
snap("3.7.round") { ri(Ruby::V4.round(3.7)) }
snap("2.5.round") { ri(Ruby::V4.round(2.5)) }
snap("3.5.round") { ri(Ruby::V4.round(3.5)) }
snap("-2.5.round") { ri(Ruby::V4.round(-2.5)) }
snap("2.5.round(half: :even)") { ri(Ruby::V4.round(2.5, half: :even)) }
snap("2.5.round(half: :down)") { ri(Ruby::V4.round(2.5, half: :down)) }
snap("3.14159.round(2)") { ri(Ruby::V4.round(3.14159, 2)) }
snap("3.14159.floor(2)") { Ruby::V4.float_to_s(3.14159.floor(2)) }
snap("3.14159.ceil(2)") { Ruby::V4.float_to_s(3.14159.ceil(2)) }
snap("3.14159.truncate(2)") { Ruby::V4.float_to_s(3.14159.truncate(2)) }
snap("(0.0/0.0).nan?") { ri((0.0 / 0.0).nan?) }
snap("(1.0/0).infinite?") { ri((1.0 / 0).infinite?) }
snap("(-1.0/0).infinite?") { ri((-1.0 / 0).infinite?) }
snap("1.0.finite?") { ri(1.0.finite?) }
snap("3.0.to_s") { ri(Ruby::V4.float_to_s(3.0)) }
snap("1e20.to_s") { ri(Ruby::V4.float_to_s(1e20)) }
snap("1e-5.to_s") { ri(Ruby::V4.float_to_s(1e-5)) }
snap("1e16.to_s") { ri(Ruby::V4.float_to_s(1e16)) }
snap("123456789012345.0.to_s") { ri(Ruby::V4.float_to_s(123456789012345.0)) }
snap("(1.0/3).to_s") { ri(Ruby::V4.float_to_s(1.0 / 3)) }
snap("0.1 + 0.2") { ri(0.1 + 0.2) }
snap("(0.1 + 0.2).round(1)") { ri(Ruby::V4.round(0.1 + 0.2, 1)) }
snap("1.5 % 2") { ri(1.5 % 2) }
snap("-1.5 % 2") { ri((-1.5) % 2) }
snap("1.5.modulo(2)") { ri(1.5.modulo(2)) }
snap("1.5.divmod(1)") { ri([(1.5 // 1).to_i64, 1.5 % 1]) }
snap("3.7.floor") { ri(3.7.floor.to_i64) }
snap("-3.7.floor") { ri((-3.7).floor.to_i64) }
snap("3.2.ceil") { ri(3.2.ceil.to_i64) }
snap("2.0.zero?") { ri(2.0.zero?) }
snap("0.0.zero?") { ri(0.0.zero?) }
snap("(2**0.5).round(4)") { ri(Ruby::V4.round(2 ** 0.5, 4)) }

# ---------------------------------------------------------------- array
snap("[3, 1, 2].sort") { ri([3, 1, 2].sort) }
snap("[3, 1, 2].sort { |a, b| b <=> a }") { ri([3, 1, 2].sort { |a, b| b <=> a }) }
snap("[1, 2, 3, 4].sum") { ri([1, 2, 3, 4].sum) }
snap("[1, 2, 3, 4].sum { |x| x * 2 }") { ri([1, 2, 3, 4].sum { |x| x * 2 }) }
snap("[1, 2, 3, 4].sum(10)") { ri([1, 2, 3, 4].sum(10)) }
snap("[1, 2, 3].min") { ri([1, 2, 3].min) }
snap("[1, 2, 3].max") { ri([1, 2, 3].max) }
snap("[1, 3, 2].minmax") { ri([1, 3, 2].minmax.to_a) }
snap("[1, 2, 3, 4].each_slice(2).to_a") { ri([1, 2, 3, 4].each_slice(2).to_a) }
snap("[1, 2, 3, 4].each_cons(2).to_a") { ri([1, 2, 3, 4].each_cons(2).to_a) }
snap("[1, 2, 3, 4].select { |x| x.even? }") { ri([1, 2, 3, 4].select { |x| x.even? }) }
snap("[1, 2, 3, 4].reject { |x| x.even? }") { ri([1, 2, 3, 4].reject { |x| x.even? }) }
snap("[1, 2, 3, 4].map { |x| x * 2 }") { ri([1, 2, 3, 4].map { |x| x * 2 }) }
snap("[1, 2, 3, 4].filter_map { |x| x.even? ? x * 10 : nil }") { ri([1, 2, 3, 4].filter_map { |x| x.even? ? x * 10 : nil }) }
snap("[1, 1, 2].uniq") { ri([1, 1, 2].uniq) }
snap("[1, 2, 3].zip([4, 5, 6])") { ri(Ruby::V4.zip([1, 2, 3], [4, 5, 6])) }
snap("[1, 2, 3].zip([4, 5])") { ri(Ruby::V4.zip([1, 2, 3], [4, 5])) }
snap("[1, 2, 3].rotate") { ri([1, 2, 3].rotate) }
snap("[1, 2, 3].rotate(-1)") { ri([1, 2, 3].rotate(-1)) }
snap("[1, 2, 3, 4].combination(2).to_a") { ri([1, 2, 3, 4].combination(2)) }
snap("[1, 2, 3].permutation(2).to_a") { ri([1, 2, 3].permutation(2)) }
snap("[1, 2].product([3, 4])") { ri([1, 2].cartesian_product([3, 4])) }
snap("[1, 2, 3, 4].first(2)") { ri([1, 2, 3, 4].first(2)) }
snap("[1, 2, 3, 4].last(2)") { ri([1, 2, 3, 4].last(2)) }
snap("[1, 2, 3, 4].take_while { |x| x < 3 }") { ri([1, 2, 3, 4].take_while { |x| x < 3 }) }
snap("[1, 2, 3, 4].drop_while { |x| x < 3 }") { ri([1, 2, 3, 4].drop_while { |x| x < 3 }) }
snap("[1, 2, 3].values_at(0, 2)") { ri([1, 2, 3].values_at(0, 2).to_a) }
snap("[1, 2, 3].values_at(0..1)") { ri([1, 2, 3].values_at(0..1)) }
snap("[1, [2, [3, [4]]]].flatten") { ri([1, [2, [3, [4]]]].flatten) }
snap("[1, [2, [3, [4]]]].flatten(1)") { ri([1, [2, [3, [4]]]].flatten(1)) }
snap("[1, nil, 2, false].compact") { ri([1, nil, 2, false].compact) }
snap("[[1, 2], [3, 4]].to_h") { ri([[1, 2], [3, 4]].to_h) }
snap("[1, 2, 3].fetch(1)") { ri([1, 2, 3].fetch(1)) }
snap("[1, 2, 3].fetch(10, \"x\")") { ri([1, 2, 3].fetch(10, "x")) }
snap("[1, 2, 3].fetch(10) { |i| i * 2 }") { ri([1, 2, 3].fetch(10) { |i| i * 2 }) }
snap("[1, 2, 3].index(2)") { ri([1, 2, 3].index(2)) }
snap("[1, 2, 3].index { |x| x > 1 }") { ri([1, 2, 3].index { |x| x > 1 }) }
snap("[1, 2, 3].rindex(3)") { ri([1, 2, 3].rindex(3)) }
snap("[1, 2, 3].include?(2)") { ri([1, 2, 3].includes?(2)) }
snap("[1, 2, 3].count(2)") { ri([1, 2, 3].count(2)) }
snap("[1, 2, 3].count { |x| x > 1 }") { ri([1, 2, 3].count { |x| x > 1 }) }
snap("[1, 2, 3].each_with_index.to_a") { ri([1, 2, 3].each_with_index.to_a) }
snap("[1, 2, 3, 4].partition { |x| x.odd? }") { ri([1, 2, 3, 4].partition { |x| x.odd? }) }
snap("[1, 2, 3, 4].group_by { |x| x % 3 }") { ri([1, 2, 3, 4].group_by { |x| x % 3 }) }
snap("[1, 2, 2, 3].tally") { ri([1, 2, 2, 3].tally) }
snap("[1, 2, 3].inject { |a, b| a + b }") { ri([1, 2, 3].inject { |a, b| a + b }) }
snap("[1, 2, 3].reduce(10) { |a, b| a + b }") { ri([1, 2, 3].reduce(10) { |a, b| a + b }) }
snap("[1, 2, 3, 4].bsearch { |x| x >= 2 }") { ri([1, 2, 3, 4].bsearch { |x| x >= 2 }) }
snap("[1, 2, 3] & [2, 3, 4]") { ri([1, 2, 3] & [2, 3, 4]) }
snap("[1, 2, 3] | [2, 3, 4]") { ri([1, 2, 3] | [2, 3, 4]) }
snap("[1, 2, 3] - [2]") { ri([1, 2, 3] - [2]) }
snap("[1, 2] * 3") { ri([1, 2] * 3) }
snap("[1, 2, 3].push(4, 5)") { a = [1, 2, 3]; ri(a.push(4, 5)) }
snap("a = [1, 2, 3]; a.pop") { a = [1, 2, 3]; ri(a.pop) }
snap("[1, 2].unshift(0)") { a = [1, 2]; ri(a.unshift(0)) }
snap("[1, 2, 3].delete_at(1)") { a = [1, 2, 3]; ri(a.delete_at(1)) }
snap("[1, 2, 3].insert(1, 9)") { a = [1, 2, 3]; ri(a.insert(1, 9)) }
snap("[[1, 2]].assoc(1)") { ri([[1, 2]].assoc(1)) }
snap("[[1, 2]].rassoc(2)") { ri([[1, 2]].rassoc(2)) }
snap("[[1, [2]]].dig(0, 1, 0)") { ri([[1, [2]]].dig(0, 1, 0)) }
snap("[3, 1, 2].max(2)") { ri([3, 1, 2].max(2)) }
snap("[3, 1, 2].min(2)") { ri([3, 1, 2].min(2)) }
snap("[1, 2, 3, 4].chunk_while { |a, b| b == a + 1 }.to_a") { ri([1, 2, 3, 4].chunk_while { |a, b| b == a + 1 }) }
snap("[1, 2, 4, 5].slice_when { |a, b| b == a + 2 }.to_a") { ri([1, 2, 4, 5].slice_when { |a, b| b == a + 2 }) }
snap("Array.new(3) { |i| i * 2 }") { ri(Array.new(3) { |i| i * 2 }) }
snap("Array.new(2, \"x\")") { ri(Array.new(2, "x")) }
snap("[].first") { ri(([] of Int32).first?) }
snap("[].sum") { ri(([] of Int32).sum) }
snap("[1, 2].join(\"-\")") { ri([1, 2].join("-")) }
snap("[1, 2, 3, 4, 5].shuffle(random: Random.new(42))") { ri([1, 2, 3, 4, 5].shuffle(Ruby::V4::Random.new(42))) }
snap("[1, 2, 3, 4, 5, 6, 7, 8].shuffle(random: Random.new(7))") { ri([1, 2, 3, 4, 5, 6, 7, 8].shuffle(Ruby::V4::Random.new(7))) }
snap("[\"a\", \"bb\", \"cc\"].min_by { |s| s.size }") { ri(["a", "bb", "cc"].min_by { |s| s.size }) }
snap("[\"a\", \"bb\", \"cc\"].sort_by { |s| s.size }") { ri(["a", "bb", "cc"].sort_by { |s| s.size }) }
snap("[1, 2, 3].each_with_object([]) { |x, acc| acc << x * 2 }") { ri([1, 2, 3].each_with_object(Array(Int64).new) { |x, acc| acc << x * 2 }) }

# ---------------------------------------------------------------- hash
snap("{\"a\"=>1, \"b\"=>2}.transform_values { |v| v * 2 }") { ri({"a" => 1, "b" => 2}.transform_values { |v| v * 2 }) }
snap("{\"a\"=>1, \"b\"=>2}.transform_keys { |k| k.upcase }") { ri({"a" => 1, "b" => 2}.transform_keys { |k| k.upcase }) }
snap("{\"a\"=>1, \"b\"=>2}.select { |k, v| v > 1 }") { ri({"a" => 1, "b" => 2}.select { |k, v| v > 1 }) }
snap("{\"a\"=>1, \"b\"=>2}.reject { |k, v| v > 1 }") { ri({"a" => 1, "b" => 2}.reject { |k, v| v > 1 }) }
snap("{\"a\"=>1, \"b\"=>2}.filter_map { |k, v| v > 1 ? k : nil }") { ri({"a" => 1, "b" => 2}.filter_map { |k, v| v > 1 ? k : nil }) }
snap("{\"a\"=>1, \"b\"=>2}.merge({\"c\"=>3})") { ri({"a" => 1, "b" => 2}.merge({"c" => 3})) }
snap("{\"a\"=>1, \"b\"=>2}.merge({\"b\"=>9}) { |k, o, n| o + n }") { ri({"a" => 1, "b" => 2}.merge({"b" => 9}) { |k, o, n| o + n }) }
snap("{\"a\"=>1, \"b\"=>2}.to_a") { ri({"a" => 1, "b" => 2}.to_a) }
snap("{\"a\"=>1, \"b\"=>2}.keys") { ri({"a" => 1, "b" => 2}.keys) }
snap("{\"a\"=>1, \"b\"=>2}.values") { ri({"a" => 1, "b" => 2}.values) }
snap("{\"a\"=>1, \"b\"=>2}.invert") { ri({"a" => 1, "b" => 2}.invert) }
snap("{\"a\"=>1, \"b\"=>2}.count") { ri({"a" => 1, "b" => 2}.size) }
snap("{\"a\"=>1, \"b\"=>2}.size") { ri({"a" => 1, "b" => 2}.size) }
snap("{\"a\"=>1, \"b\"=>2}.length") { ri({"a" => 1, "b" => 2}.size) }
snap("h = {\"a\"=>1}; h[\"a\"]") { ri({"a" => 1}["a"]) }
snap("{\"a\"=>1}.fetch(\"a\")") { ri({"a" => 1}.fetch("a")) }
snap("{\"a\"=>1}.fetch(\"z\", 0)") { ri({"a" => 1}.fetch("z", 0)) }
snap("{\"a\"=>1}.fetch(\"z\") { |k| k.size }") { ri({"a" => 1}.fetch("z") { |k| k.size }) }
snap("{\"a\"=>1}.key?(\"a\")") { ri({"a" => 1}.has_key?("a")) }
snap("{\"a\"=>1}.value?(1)") { ri({"a" => 1}.has_value?(1)) }
snap("{\"a\"=>1}.key(1)") { ri({"a" => 1}.key(1)) }
snap("{\"a\"=>1, \"b\"=>2}.each_with_index.to_a") { ri({"a" => 1, "b" => 2}.each_with_index.to_a) }
snap("{\"a\"=>1, \"b\"=>2}.min_by { |k, v| v }") { ri({"a" => 1, "b" => 2}.min_by { |k, v| v }.to_a) }
snap("{\"a\"=>1, \"b\"=>2}.max_by { |k, v| v }") { ri({"a" => 1, "b" => 2}.max_by { |k, v| v }.to_a) }
snap("{\"a\"=>1, \"b\"=>2}.sum { |k, v| v }") { ri({"a" => 1, "b" => 2}.sum { |k, v| v }) }
snap("{\"a\"=>1, \"b\"=>2}.any? { |k, v| v > 1 }") { ri({"a" => 1, "b" => 2}.any? { |k, v| v > 1 }) }
snap("{\"a\"=>1, \"b\"=>2}.all? { |k, v| v > 0 }") { ri({"a" => 1, "b" => 2}.all? { |k, v| v > 0 }) }
snap("{\"a\"=>1, \"b\"=>2}.partition { |k, v| v > 1 }") { ri({"a" => 1, "b" => 2}.partition { |k, v| v > 1 }) }
snap("{\"a\"=>1, \"b\"=>2}.group_by { |k, v| v % 2 }") { ri({"a" => 1, "b" => 2}.group_by { |k, v| v % 2 }) }
snap("{\"a\"=>1}.dig(\"a\")") { ri({"a" => 1}.dig("a")) }
snap("{\"x\"=>{\"y\"=>1}}.dig(\"x\", \"y\")") { ri({"x" => {"y" => 1}}.dig("x", "y")) }
snap("{\"a\"=>1, \"b\"=>2}.slice(\"a\")") { ri({"a" => 1, "b" => 2}.slice("a")) }
snap("{\"a\"=>1, \"b\"=>2}.except(\"a\")") { ri({"a" => 1, "b" => 2}.except("a")) }
snap("Hash[[[\"a\", 1]]]") { ri([["a", 1]].to_h) }
snap("{\"a\"=>nil, \"b\"=>2}.compact") { ri({"a" => nil, "b" => 2}.compact) }
snap("{\"a\"=>1, \"b\"=>2}.find { |k, v| v > 1 }") { r = {"a" => 1, "b" => 2}.find { |k, v| v > 1 }; ri(r ? r.to_a : nil) }
snap("{\"a\"=>1, \"b\"=>2}.sort_by { |k, v| v }.to_h") { ri({"a" => 1, "b" => 2}.sort_by { |k, v| v }.to_h) }
snap("{\"a\"=>1, \"b\"=>2}.min") { ri({"a" => 1, "b" => 2}.min.to_a) }
snap("{\"a\"=>1, \"b\"=>2}.max") { ri({"a" => 1, "b" => 2}.max.to_a) }
snap("{\"b\"=>2, \"a\"=>1}.sort.to_h") { ri({"b" => 2, "a" => 1}.to_a.sort.to_h) }
snap("{\"a\"=>1, \"b\"=>2}.each_pair.to_a") { ri({"a" => 1, "b" => 2}.to_a) }
snap("{\"a\"=>1, \"b\"=>2}.count { |k, v| v > 1 }") { ri({"a" => 1, "b" => 2}.count { |k, v| v > 1 }) }
snap("{\"a\"=>1, \"b\"=>2}.each_with_object([]) { |(k, v), acc| acc << k }") { ri({"a" => 1, "b" => 2}.each_with_object(Array(String).new) { |(k, v), acc| acc << k }) }

# ---------------------------------------------------------------- set
snap("Set[1, 2, 3].to_a") { ri(Set{1, 2, 3}.to_a) }
snap("Set[1, 2] | Set[3]") { ri(Set{1, 2} | Set{3}) }
snap("Set[1, 2] & Set[2, 3]") { ri(Set{1, 2} & Set{2, 3}) }
snap("Set[1, 2, 3] - Set[2]") { ri(Set{1, 2, 3} - Set{2}) }
snap("Set[1, 2] ^ Set[2, 3]") { ri(VER == "v3" ? Ruby::V3.set_xor(Set{1, 2}, Set{2, 3}) : Set{1, 2} ^ Set{2, 3}) }
snap("Set[1, 2].add(3)") { s = Set{1, 2}; s.add(3); ri(s) }
snap("s = Set[1, 2]; s.add?(1)") { s = Set{1, 2}; ri(Ruby::V4.set_add?(s, 1)) }
snap("Set[1, 2].add?(3)") { s = Set{1, 2}; ri(Ruby::V4.set_add?(s, 3)) }
snap("Set[1, 2].subset?(Set[1, 2, 3])") { ri(Set{1, 2}.subset?(Set{1, 2, 3})) }
snap("Set[1, 2].superset?(Set[1])") { ri(Set{1, 2}.superset?(Set{1})) }
snap("Set[1, 2] <= Set[1, 2]") { ri(Set{1, 2} <= Set{1, 2}) }
snap("Set[1, 2] < Set[1, 2]") { ri(Set{1, 2} < Set{1, 2}) }
snap("Set[1, 2].disjoint?(Set[3])") { ri(Set{1, 2}.disjoint?(Set{3})) }
snap("Set[1, 2].intersect?(Set[2])") { ri(Set{1, 2}.intersect?(Set{2})) }
snap("Set[1, 2] == Set[2, 1]") { ri(Set{1, 2} == Set{2, 1}) }
snap("Set[1, 2].include?(1)") { ri(Set{1, 2}.includes?(1)) }
snap("Set[1, 2].size") { ri(Set{1, 2}.size) }
snap("Set[1, 2].empty?") { ri(Set{1, 2}.empty?) }
snap("Set.new.empty?") { ri(Set(Int32).new.empty?) }
snap("Set[3, 1, 2].sort.to_a") { ri(Set{3, 1, 2}.sort) }
snap("Set[1, 2].map { |x| x * 2 }") { ri(Set{1, 2}.map { |x| x * 2 }) }
snap("Set[1, 2, 3].select { |x| x.odd? }.to_a.sort") { ri(Set{1, 2, 3}.select { |x| x.odd? }.to_a.sort) }
snap("Set[1, 2].inspect") { ri(ri(Set{1, 2})) }
snap("Set[1, 2].to_s") { ri(ri(Set{1, 2})) }
snap("Set.new([1, 2]) == Set[1, 2]") { ri(Set.new([1, 2]) == Set{1, 2}) }

# ---------------------------------------------------------------- range
snap("(1..5).to_a") { ri((1..5).to_a) }
snap("(1...5).to_a") { ri((1...5).to_a) }
snap("('a'..'e').to_a") { ri(('a'..'e').to_a) }
snap("(1..10).step(3).to_a") { ri((1..10).step(3).to_a) }
snap("('a'..'e').step(2).to_a") { ri(('a'..'e').step(2).to_a) }
snap("(1..5).step(2).to_a") { ri((1..5).step(2).to_a) }
snap("(1.0..2.0).step(0.5).to_a") { ri((1.0..2.0).step(0.5).to_a) }
snap("(1..5).size") { ri((1..5).size) }
snap("(1...5).size") { ri((1...5).size) }
snap("(1..5).count") { ri((1..5).size) }
snap("(1..5).sum") { ri((1..5).sum) }
snap("(1..3).sum { |x| x * 2 }") { ri((1..3).sum { |x| x * 2 }) }
snap("(1..5).min") { ri((1..5).min) }
snap("(1..5).max") { ri((1..5).max) }
snap("(1..5).first(3)") { ri((1..5).to_a.first(3)) }
snap("(1..5).last(3)") { ri((1..5).to_a.last(3)) }
snap("(1..5).first") { ri((1..5).begin) }
snap("(1..5).last") { ri((1..5).end) }
snap("(1..5).include?(3)") { ri((1..5).includes?(3)) }
snap("(1..5).cover?(3)") { ri((1..5).cover?(3)) }
snap("(1..5).cover?(0)") { ri((1..5).cover?(0)) }
snap("(1..5) === 3") { ri((1..5) === 3) }
snap("(1..10) === 5.0") { ri((1..10) === 5.0) }
snap("(1..10).select { |x| x.even? }") { ri((1..10).select { |x| x.even? }) }
snap("(1..6).map { |x| x * x }") { ri((1..6).map { |x| x * x }) }
snap("(1..5).reduce { |a, b| a + b }") { ri((1..5).reduce { |a, b| a + b }) }
snap("(1..3).each_slice(2).to_a") { ri((1..3).each_slice(2).to_a) }
snap("(1..3).overlap?(3..5)") { ri((1..3).overlap?(3..5)) }
snap("(1..3).overlap?(4..5)") { ri((1..3).overlap?(4..5)) }
snap("(1..).first(3)") { ri(Range.new(1, nil).first(3)) }
snap("(-3..3).select { |x| x.negative? }") { ri((-3..3).select { |x| x.negative? }) }

# ---------------------------------------------------------------- time
snap("Time.at(0).utc.to_s") { ri(T.at(0).utc.to_s) }
snap("Time.at(0).utc.inspect") { ri(T.at(0).utc.inspect) }
snap("Time.at(0).to_i") { ri(T.at(0).to_i) }
snap("Time.at(0).utc.iso8601") { ri(T.at(0).utc.iso8601) }
snap("Time.at(0.5).utc.iso8601") { ri(T.at(0.5).utc.iso8601) }
snap("Time.at(0.123456789).utc.iso8601(9)") { ri(T.at(0.123456789).utc.iso8601(9)) }
snap("Time.at(0.123456789).usec") { ri(T.at(0.123456789).usec) }
snap("Time.at(0.123456789).nsec") { ri(T.at(0.123456789).nsec) }
snap("Time.gm(2026,1,2,3,4,5).to_s") { ri(T.gm(2026, 1, 2, 3, 4, 5).to_s) }
snap("Time.gm(2026,1,2,3,4,5).inspect") { ri(T.gm(2026, 1, 2, 3, 4, 5).inspect) }
snap("Time.utc(2026,1,2,3,4,5).to_s") { ri(T.utc(2026, 1, 2, 3, 4, 5).to_s) }
snap("Time.local(2026,1,2,3,4,5).to_s") { ri(T.local(2026, 1, 2, 3, 4, 5).to_s) }
snap("Time.mktime(2026,1,2).to_s") { ri(T.mktime(2026, 1, 2).to_s) }
snap("Time.new(2026,1,2,3,4,5,\"+05:30\").to_s") { ri(T.new(2026, 1, 2, 3, 4, 5, "+05:30").to_s) }
snap("Time.new(2026,1,2,3,4,5,\"+05:30\").utc_offset") { ri(T.new(2026, 1, 2, 3, 4, 5, "+05:30").utc_offset) }
snap("Time.new(2026,1,2,3,4,5,\"+05:30\").zone") { ri(T.new(2026, 1, 2, 3, 4, 5, "+05:30").zone) }
snap("Time.new(2026,1,2,3,4,5,\"+05:30\").utc.to_s") { ri(T.new(2026, 1, 2, 3, 4, 5, "+05:30").utc.to_s) }
snap("Time.at(0).getlocal.utc_offset") { ri(T.at(0).getlocal.utc_offset) }
snap("Time.gm(2026,1,2).wday") { ri(T.gm(2026, 1, 2).wday) }
snap("Time.gm(2026,1,2).yday") { ri(T.gm(2026, 1, 2).yday) }
snap("Time.gm(2026,1,2).mday") { ri(T.gm(2026, 1, 2).mday) }
snap("Time.gm(2026,1,2).day") { ri(T.gm(2026, 1, 2).day) }
snap("Time.gm(2026,1,2).mon") { ri(T.gm(2026, 1, 2).mon) }
snap("Time.gm(2026,1,2).month") { ri(T.gm(2026, 1, 2).month) }
snap("Time.gm(2026,1,2).year") { ri(T.gm(2026, 1, 2).year) }
snap("Time.gm(2026,1,2,3,4,5).hour") { ri(T.gm(2026, 1, 2, 3, 4, 5).hour) }
snap("Time.gm(2026,1,2,3,4,5).min") { ri(T.gm(2026, 1, 2, 3, 4, 5).min) }
snap("Time.gm(2026,1,2,3,4,5).sec") { ri(T.gm(2026, 1, 2, 3, 4, 5).sec) }
snap("Time.gm(2026,1,2).to_a") { ri(T.gm(2026, 1, 2).to_a) }
snap("Time.gm(2026,1,2).monday?") { ri(T.gm(2026, 1, 2).monday?) }
snap("Time.gm(2026,1,2).friday?") { ri(T.gm(2026, 1, 2).friday?) }
snap("Time.gm(2026,1,2).utc?") { ri(T.gm(2026, 1, 2).utc?) }
snap("Time.gm(2026,1,2).dst?") { ri(T.gm(2026, 1, 2).dst?) }
snap("Time.at(0).dst?") { ri(T.at(0).dst?) }
snap("Time.gm(2026,1,2) + 86400") { (T.gm(2026, 1, 2) + 86400).to_s }
snap("Time.gm(2026,1,2) - 3600") { (T.gm(2026, 1, 2) - 3600).to_s }
snap("Time.gm(2026,1,2) - Time.gm(2025,12,31)") { Ruby::V4.float_to_s(T.gm(2026, 1, 2) - T.gm(2025, 12, 31)) }
snap("Time.gm(2026,1,2) <=> Time.gm(2025,12,31)") { ri(T.gm(2026, 1, 2) <=> T.gm(2025, 12, 31)) }
snap("Time.gm(2026,1,2) == Time.gm(2026,1,2)") { ri(T.gm(2026, 1, 2) == T.gm(2026, 1, 2)) }
snap("t = Time.gm(2026,1,2,3,4,5); t.strftime(\"%Y-%m-%d %H:%M:%S\")") { ri(T.gm(2026, 1, 2, 3, 4, 5).strftime("%Y-%m-%d %H:%M:%S")) }
snap("t.strftime(\"%F %T\")") { ri(T.gm(2026, 1, 2, 3, 4, 5).strftime("%F %T")) }
snap("t.strftime(\"%D %R %r\")") { ri(T.gm(2026, 1, 2, 3, 4, 5).strftime("%D %R %r")) }
snap("t.strftime(\"%e\")") { ri(T.gm(2026, 1, 2, 3, 4, 5).strftime("%e")) }
snap("t.strftime(\"%-d %-m\")") { ri(T.gm(2026, 1, 2, 3, 4, 5).strftime("%-d %-m")) }
snap("t.strftime(\"%^A\")") { ri(T.gm(2026, 1, 2, 3, 4, 5).strftime("%^A")) }
snap("t.strftime(\"%_m\")") { ri(T.gm(2026, 1, 2, 3, 4, 5).strftime("%_m")) }
snap("t.strftime(\"%C %y %G %V %u\")") { ri(T.gm(2026, 1, 2, 3, 4, 5).strftime("%C %y %G %V %u")) }
snap("t.strftime(\"%j %U %W\")") { ri(T.gm(2026, 1, 2, 3, 4, 5).strftime("%j %U %W")) }
snap("t.strftime(\"%a %A %b %B %h\")") { ri(T.gm(2026, 1, 2, 3, 4, 5).strftime("%a %A %b %B %h")) }
snap("t.strftime(\"%k %l %P %p\")") { ri(T.gm(2026, 1, 2, 3, 4, 5).strftime("%k %l %P %p")) }
snap("t.strftime(\"%c\")") { ri(T.gm(2026, 1, 2, 3, 4, 5).strftime("%c")) }
snap("t.strftime(\"%x %X\")") { ri(T.gm(2026, 1, 2, 3, 4, 5).strftime("%x %X")) }
snap("t.strftime(\"%s\")") { ri(T.gm(2026, 1, 2, 3, 4, 5).strftime("%s")) }
snap("t.strftime(\"%%\")") { ri(T.gm(2026, 1, 2, 3, 4, 5).strftime("%%")) }
snap("t.strftime(\"[%n]\")") { ri(T.gm(2026, 1, 2, 3, 4, 5).strftime("[%n]")) }
snap("t.strftime(\"%z\")") { ri(T.gm(2026, 1, 2, 3, 4, 5).strftime("%z")) }
snap("Time.new(2026,1,2,3,4,5,\"+05:30\").strftime(\"%z %Z\")") { ri(T.new(2026, 1, 2, 3, 4, 5, "+05:30").strftime("%z %Z")) }
snap("t.strftime(\"%Z\")") { ri(T.gm(2026, 1, 2, 3, 4, 5).strftime("%Z")) }
snap("Time.at(0).utc.strftime(\"%Z\")") { ri(T.at(0).utc.strftime("%Z")) }
snap("t.strftime(\"%+\")") { ri(T.gm(2026, 1, 2, 3, 4, 5).strftime("%+")) }
snap("t2 = Time.at(0.123456789).utc; t2.strftime(\"%L\")") { ri(T.at(0.123456789).utc.strftime("%L")) }
snap("t2.strftime(\"%N\")") { ri(T.at(0.123456789).utc.strftime("%N")) }
snap("t2.strftime(\"%3N %6N %9N\")") { ri(T.at(0.123456789).utc.strftime("%3N %6N %9N")) }
snap("t2.strftime(\"%.3N\")") { ri(T.at(0.123456789).utc.strftime("%.3N")) }
snap("Time.parse(\"2026-01-02 03:04:05 UTC\").to_s") { ri(T.parse("2026-01-02 03:04:05 UTC").to_s) }
snap("Time.parse(\"2026-01-02T03:04:05+05:30\").utc.to_s") { ri(T.parse("2026-01-02T03:04:05+05:30").utc.to_s) }
snap("Time.parse(\"Fri, 02 Jan 2026 03:04:05 GMT\").to_s") { ri(T.parse("Fri, 02 Jan 2026 03:04:05 GMT").to_s) }
snap("Time.gm(2026,1,2,3,4,5).httpdate") { ri(T.gm(2026, 1, 2, 3, 4, 5).httpdate) }
snap("Time.gm(2026,1,2,3,4,5).rfc2822") { ri(T.gm(2026, 1, 2, 3, 4, 5).rfc2822) }
snap("Time.gm(2026,1,2,3,4,5).iso8601") { ri(T.gm(2026, 1, 2, 3, 4, 5).iso8601) }
snap("Time.gm(2026,1,2,3,4,5).xmlschema") { ri(T.gm(2026, 1, 2, 3, 4, 5).xmlschema) }
snap("Time.at(0.123456789).utc.xmlschema(6)") { ri(T.at(0.123456789).utc.xmlschema(6)) }
snap("Time.gm(2026,1,2).getutc.zone") { ri(T.gm(2026, 1, 2).getutc.zone) }
snap("Time.utc(1900,1,1).to_s") { ri(T.utc(1900, 1, 1).to_s) }
snap("Time.gm(2024,2,29).to_s") { ri(T.gm(2024, 2, 29).to_s) }

# ---------------------------------------------------------------- date
snap("Date.new(2026,1,2).to_s") { ri(D.new(2026, 1, 2).to_s) }
snap("Date.new(2026,1,2).iso8601") { ri(D.new(2026, 1, 2).iso8601) }
snap("Date.new(2026,1,2).inspect") { ri(D.new(2026, 1, 2).inspect) }
snap("Date.new(2026,1,2).jd") { ri(D.new(2026, 1, 2).jd) }
snap("Date.new(2026,1,2).mjd") { ri(D.new(2026, 1, 2).mjd) }
snap("Date.new(2026,1,2).yday") { ri(D.new(2026, 1, 2).yday) }
snap("Date.new(2026,1,2).wday") { ri(D.new(2026, 1, 2).wday) }
snap("Date.new(2026,1,2).cwday") { ri(D.new(2026, 1, 2).cwday) }
snap("Date.new(2026,1,2).cweek") { ri(D.new(2026, 1, 2).cweek) }
snap("Date.new(2026,1,2).cwyear") { ri(D.new(2026, 1, 2).cwyear) }
snap("Date.new(2026,1,2).day") { ri(D.new(2026, 1, 2).day) }
snap("Date.new(2026,1,2).mday") { ri(D.new(2026, 1, 2).mday) }
snap("Date.new(2026,1,2).mon") { ri(D.new(2026, 1, 2).mon) }
snap("Date.new(2026,1,2).month") { ri(D.new(2026, 1, 2).month) }
snap("Date.new(2026,1,2).year") { ri(D.new(2026, 1, 2).year) }
snap("Date.new(2026,1,2).friday?") { ri(D.new(2026, 1, 2).friday?) }
snap("Date.leap?(2024)") { ri(D.leap?(2024)) }
snap("Date.leap?(2023)") { ri(D.leap?(2023)) }
snap("Date.leap?(2000)") { ri(D.leap?(2000)) }
snap("Date.leap?(1900)") { ri(D.leap?(1900)) }
snap("Date.new(2026,1,2) + 30") { (D.new(2026, 1, 2) + 30).inspect }
snap("Date.new(2026,3,1) - 1") { (D.new(2026, 3, 1) - 1).inspect }
snap("Date.new(2026,1,2) - Date.new(2025,12,31)") { Ruby::V4.rational_inspect(D.new(2026, 1, 2) - D.new(2025, 12, 31), 1) }
snap("Date.new(2026,1,2).next_day.to_s") { ri(D.new(2026, 1, 2).next_day.to_s) }
snap("Date.new(2026,1,2).prev_day.to_s") { ri(D.new(2026, 1, 2).prev_day.to_s) }
snap("Date.new(2026,1,2).next_month.to_s") { ri(D.new(2026, 1, 2).next_month.to_s) }
snap("Date.new(2026,1,2).prev_month.to_s") { ri(D.new(2026, 1, 2).prev_month.to_s) }
snap("Date.new(2026,1,2).next_year.to_s") { ri(D.new(2026, 1, 2).next_year.to_s) }
snap("Date.new(2026,1,31).next_month.to_s") { ri(D.new(2026, 1, 31).next_month.to_s) }
snap("Date.new(2026,1,2).succ.to_s") { ri(D.new(2026, 1, 2).succ.to_s) }
snap("Date.parse(\"2026-01-02\").to_s") { ri(D.parse("2026-01-02").to_s) }
snap("Date.iso8601(\"2026-01-02\").to_s") { ri(D.iso8601("2026-01-02").to_s) }
snap("Date.ordinal(2026,100).to_s") { ri(D.ordinal(2026, 100).to_s) }
snap("Date.civil(2026,2,3).to_s") { ri(D.civil(2026, 2, 3).to_s) }
snap("Date.jd(Date.new(2026,1,2).jd).to_s") { ri(D.jd(D.new(2026, 1, 2).jd).to_s) }
snap("Date.commercial(2026,1,1).to_s") { ri(D.commercial(2026, 1, 1).to_s) }
snap("(Date.new(2026,1,2)..Date.new(2026,1,4)).to_a.map { |d| d.to_s }") { ri((D.new(2026, 1, 2)..D.new(2026, 1, 4)).map { |d| d.to_s }) }
snap("Date.new(2026,1,2).step(Date.new(2026,1,5)).to_a.map { |d| d.to_s }") { ri(D.new(2026, 1, 2).step(D.new(2026, 1, 5)).map { |d| d.to_s }) }
snap("Date.new(2026,1,2).step(Date.new(2026,1,9), 2).to_a.map { |d| d.to_s }") { ri(D.new(2026, 1, 2).step(D.new(2026, 1, 9), 2).map { |d| d.to_s }) }
snap("Date.new(2026,1,2).upto(Date.new(2026,1,4)).to_a.map { |d| d.to_s }") { ri(D.new(2026, 1, 2).upto(D.new(2026, 1, 4)).map { |d| d.to_s }) }
snap("Date.new(2026,6,1).downto(Date.new(2026,5,30)).to_a.map { |d| d.to_s }") { ri(D.new(2026, 6, 1).downto(D.new(2026, 5, 30)).map { |d| d.to_s }) }
snap("Date.new(1582,10,4).julian?") { ri(D.new(1582, 10, 4).julian?) }
snap("Date.new(1582,10,15).gregorian?") { ri(D.new(1582, 10, 15).gregorian?) }
snap("Date.new(1582,10,15).to_s") { ri(D.new(1582, 10, 15).to_s) }
snap("Date.new(1582,10,4).to_s") { ri(D.new(1582, 10, 4).to_s) }
snap("Date.new(2026,1,2).julian?") { ri(D.new(2026, 1, 2).julian?) }
snap("Date.new(2026,1,2).gregorian?") { ri(D.new(2026, 1, 2).gregorian?) }
snap("Date.new(2026,1,2).asctime") { ri(D.new(2026, 1, 2).asctime) }
snap("Date.new(2026,1,2).strftime(\"%Y-%m-%d %A %j %V %G %u\")") { ri(D.new(2026, 1, 2).strftime("%Y-%m-%d %A %j %V %G %u")) }
snap("Date.new(2026,1,2) <=> Date.new(2026,1,1)") { ri(D.new(2026, 1, 2) <=> D.new(2026, 1, 1)) }
snap("Date.new(2026,1,2) == Date.new(2026,1,2)") { ri(D.new(2026, 1, 2) == D.new(2026, 1, 2)) }
snap("Date.new(2026,1,2).between?(Date.new(2026,1,1), Date.new(2026,1,3))") { ri(D.new(2026, 1, 2).between?(D.new(2026, 1, 1), D.new(2026, 1, 3))) }
snap("DateTime.civil(2026,1,2,3,4,5).to_s") { ri(DT.civil(2026, 1, 2, 3, 4, 5).to_s) }
snap("DateTime.iso8601(\"2026-01-02T03:04:05+05:30\").to_s") { ri(DT.iso8601("2026-01-02T03:04:05+05:30").to_s) }
snap("DateTime.civil(2026,1,2,3,4,5).new_offset(0).to_s") { ri(DT.civil(2026, 1, 2, 3, 4, 5).new_offset(0).to_s) }
snap("DateTime.civil(2026,1,2,3,4,5).new_offset(\"+05:30\").to_s") { ri(DT.civil(2026, 1, 2, 3, 4, 5).new_offset("+05:30").to_s) }
snap("DateTime.civil(2026,1,2,3,4,5).inspect") { ri(DT.civil(2026, 1, 2, 3, 4, 5).inspect) }
snap("DateTime.jd(Date.new(2026,1,2).jd).to_s") { ri(DT.jd(D.new(2026, 1, 2).jd).to_s) }
snap("(Date.today.year > 2025).to_s") { ri((D.today.year > 2025).to_s) }

# ---------------------------------------------------------------- random
snap("Random.new(42).rand") { Ruby::V4.float_to_s(R.new(42).rand) }
snap("Random.new(0).rand") { Ruby::V4.float_to_s(R.new(0).rand) }
snap("Random.new(1).rand") { Ruby::V4.float_to_s(R.new(1).rand) }
snap("Random.new(-1).rand") { Ruby::V4.float_to_s(R.new(-1).rand) }
snap("Random.new(2**64).rand") { Ruby::V4.float_to_s(R.new(1.to_big_i << 64).rand) }
snap("Random.new(42).rand(100)") { ri(R.new(42).rand(100)) }
snap("r = Random.new(42); (1..5).map { r.rand }") { r = R.new(42); ri((1..5).map { r.rand }) }
snap("r = Random.new(42); (1..5).map { r.rand(1000) }") { r = R.new(42); ri((1..5).map { r.rand(1000) }) }
snap("r = Random.new(42); (1..5).map { r.rand(10..20) }") { r = R.new(42); ri((1..5).map { r.rand(10..20) }) }
snap("r = Random.new(42); (1..3).map { r.rand(1.5) }") { r = R.new(42); ri((1..3).map { r.rand(1.5) }) }
snap("Random.new(123).rand(2.0)") { Ruby::V4.float_to_s(R.new(123).rand(2.0)) }
snap("r = Random.new(9); (1..3).map { r.rand(2**40) }") { r = R.new(9); ri((1..3).map { r.rand(1.to_big_i << 40) }) }
snap("r = Random.new(5); (1..3).map { r.rand(2**32) }") { r = R.new(5); ri((1..3).map { r.rand(1.to_big_i << 32) }) }
snap("r = Random.new(5); (1..3).map { r.rand(2**32 - 1) }") { r = R.new(5); ri((1..3).map { r.rand((1.to_big_i << 32) - 1) }) }
snap("Random.new(42).bytes(8).bytes") { ri(R.new(42).bytes(8)) }
snap("Random.new(42).bytes(16).bytes") { ri(R.new(42).bytes(16)) }
snap("Random.new(7).bytes(5).bytes") { ri(R.new(7).bytes(5)) }
snap("srand(99); rand") { Ruby::V4::Random.srand(99); Ruby::V4.float_to_s(Ruby::V4::Random.rand) }
snap("srand(99); rand(1000)") { Ruby::V4::Random.srand(99); ri(Ruby::V4::Random.rand(1000)) }
snap("r = Random.new(3); (1..3).map { r.bytes(4).bytes }") { r = R.new(3); ri((1..3).map { r.bytes(4) }) }
snap("[1, 2, 3, 4, 5].shuffle(random: Random.new(42))") { ri([1, 2, 3, 4, 5].shuffle(R.new(42))) }
snap("[1, 2, 3, 4, 5, 6, 7, 8].shuffle(random: Random.new(7))") { ri([1, 2, 3, 4, 5, 6, 7, 8].shuffle(R.new(7))) }
snap("r = Random.new(42); (1..2).map { r.rand(2**62) }") { r = R.new(42); ri((1..2).map { r.rand(1.to_big_i << 62) }) }

# ---------------------------------------------------------------- struct
snap("Point.new(1,2).to_s") { ri(Point.new(1, 2).to_s) }
snap("Point.new(1,2).inspect") { ri(Point.new(1, 2).inspect) }
snap("Point.new(1,2).to_a") { ri(Point.new(1, 2).to_a) }
snap("Point.new(1,2).values") { ri(Point.new(1, 2).values) }
snap("Point.new(1,2).to_h") { p = Point.new(1, 2); pairs = [] of Tuple(String, Ruby::V4::Struct::Value); p.to_a.each_with_index { |v, i| pairs << {p.members[i], v} }; Ruby::V4.sym_hash_inspect(pairs) }
snap("Point.members") { Ruby::V4.sym_array_inspect(Point.members) }
snap("Point.new(1,2) == Point.new(1,2)") { ri(Point.new(1, 2) == Point.new(1, 2)) }
snap("Point.new(1,2) == Point.new(0,2)") { ri(Point.new(1, 2) == Point.new(0, 2)) }
snap("Point.new(1,2)[0]") { ri(Point.new(1, 2)[0]) }
snap("Point.new(1,2)[1]") { ri(Point.new(1, 2)[1]) }
snap("Point.new(1,2)[\"x\"]") { ri(Point.new(1, 2)["x"]) }
snap("Point.new(1,2).each.to_a") { ri(Point.new(1, 2).to_a) }
snap("Point.new(1,2).each_pair.to_a") { p = Point.new(1, 2); "[" + p.members.zip(p.values).map { |k, v| "[:#{k}, #{Ruby::V4.inspect(v)}]" }.join(", ") + "]" }
snap("Point.new(1,2).size") { ri(Point.new(1, 2).size) }
snap("Point.new(1,2).length") { ri(Point.new(1, 2).length) }
snap("p = Point.new(1,2); p.x = 3; p.to_s") { p = Point.new(1, 2); p.x = 3; ri(p.to_s) }
snap("p = Point.new(1,2); p[0] = 9; p.to_a") { p = Point.new(1, 2); p[0] = 9; ri(p.to_a) }
snap("KwPoint.new(a: 1, b: 2).to_s") { ri(KwPoint.new(a: 1, b: 2).to_s) }
snap("KwPoint.new(a: 1).to_s") { ri(KwPoint.new(a: 1).to_s) }
snap("Struct.new(:a).new(1).to_s") { ri(Ruby::V4::Struct.anon(["a"]).new(1).to_s) }

# ---------------------------------------------------------------- random (новые)
snap("r = Random.new(1); (1..3).map { r.rand(1.5..3.0) }") { r = R.new(1); ri((1..3).map { r.rand(1.5..3.0) }) }
snap("r = Random.new(4); (1..3).map { r.rand(1..3.5) }") { r = R.new(4); ri((1..3).map { r.rand((1)..(3.5)) }) }
snap("r = Random.new(5); r.rand(10...20)") { ri(R.new(5).rand(10...20)) }
snap("Random.new(42).rand(0..0)") { ri(R.new(42).rand(0..0)) }
snap("[1, 2, 3, 4, 5].sample(random: Random.new(42))") { ri([1, 2, 3, 4, 5].sample(R.new(42))) }
snap("[1, 2, 3, 4, 5, 6, 7, 8].sample(random: Random.new(7))") { ri([1, 2, 3, 4, 5, 6, 7, 8].sample(R.new(7))) }
snap("[].sample(random: Random.new(1))") { ri(([] of Int32).sample(R.new(1))) }
snap("r = Random.new(1); (1..3).map { [1, 2, 3, 4, 5].sample(random: r) }") { r = R.new(1); ri((1..3).map { [1, 2, 3, 4, 5].sample(r) }) }
snap("r = Random.new(3); [1, 2, 3, 4, 5].sample(2, random: r)") { r = R.new(3); ri([1, 2, 3, 4, 5].sample(2, r)) }
snap("r = Random.new(9); [1, 2, 3, 4, 5, 6, 7, 8].sample(3, random: r)") { r = R.new(9); ri([1, 2, 3, 4, 5, 6, 7, 8].sample(3, r)) }
snap("r = Random.new(2); [1, 2, 3].sample(3, random: r)") { r = R.new(2); ri([1, 2, 3].sample(3, r)) }

# ---------------------------------------------------------------- time (новые)
snap("Time.at(0).to_s") { ri(T.at(0).to_s) }
snap("Time.at(1, 500, :millisecond)") { ri(T.at(1, 500, :millisecond)) }
snap("Time.at(1, 500000, :usec)") { ri(T.at(1, 500000, :usec)) }
snap("Time.at(0).zone") { ri(T.at(0).zone) }
snap("Time.mktime(2026,6,1).zone") { ri(T.mktime(2026, 6, 1).zone) }
snap("Time.local(2026,1,2,3,4,5).strftime(\"%Z\")") { ri(T.local(2026, 1, 2, 3, 4, 5).strftime("%Z")) }
snap("t.strftime(\"%:z\")") { ri(T.gm(2026, 1, 2, 3, 4, 5).strftime("%:z")) }
snap("Time.new(2026,1,2,3,4,5,\"+05:30\").strftime(\"%:z %::z\")") { ri(T.new(2026, 1, 2, 3, 4, 5, "+05:30").strftime("%:z %::z")) }
snap("Time.at(0.123456789).subsec") { ri(T.at(0.123456789).subsec) }
snap("Time.at(0.5).subsec") { ri(T.at(0.5).subsec) }
snap("Time.at(1.5).to_s") { ri(T.at(1.5).to_s) }
snap("Time.parse(\"2026-01-02 03:04:05 +0300\").to_s") { ri(T.parse("2026-01-02 03:04:05 +0300").to_s) }
snap("Time.parse(\"2026-01-02T03:04:05Z\").to_s") { ri(T.parse("2026-01-02T03:04:05Z").to_s) }
snap("Time.parse(\"2026-01-02\").to_s") { ri(T.parse("2026-01-02").to_s) }
snap("Time.parse(\"2026/01/02 03:04:05\").to_s") { ri(T.parse("2026/01/02 03:04:05").to_s) }
snap("Time.parse(\"2026-01-02 03:04:05\").utc_offset") { ri(T.parse("2026-01-02 03:04:05").utc_offset) }

# ---------------------------------------------------------------- date (новые)
snap("Date.parse(\"2026/01/02\").to_s") { ri(D.parse("2026/01/02").to_s) }
snap("Date.parse(\"January 2, 2026\").to_s") { ri(D.parse("January 2, 2026").to_s) }
snap("Date.parse(\"2 Jan 2026\").to_s") { ri(D.parse("2 Jan 2026").to_s) }
snap("Date.parse(\"Jan 2, 2026\").to_s") { ri(D.parse("Jan 2, 2026").to_s) }
snap("DateTime.parse(\"2026-01-02T03:04:05+05:30\").to_s") { ri(DT.parse("2026-01-02T03:04:05+05:30").to_s) }
snap("Date.jd(0).to_s") { ri(D.jd(0).to_s) }
snap("Date.jd(0).wday") { ri(D.jd(0).wday) }
snap("Date.new(-1, 1, 1).to_s") { ri(D.new(-1, 1, 1).to_s) }
snap("Date.new(-1, 1, 1).inspect") { ri(D.new(-1, 1, 1).inspect) }

# ---------------------------------------------------------------- string (новые)
snap("\"abc\".casecmp(\"ABC\")") { ri("abc".casecmp("ABC")) }
snap("\"abc\".casecmp(\"abd\")") { ri("abc".casecmp("abd")) }
snap("\"abc\".casecmp?(\"ABC\")") { ri("abc".casecmp?("ABC")) }
snap("\"abc\".casecmp?(\"abd\")") { ri("abc".casecmp?("abd")) }
snap("\"a9\".upto(\"b1\").to_a") { ri("a9".upto("b1")) }
snap("\"aa\".upto(\"ac\", true).to_a") { ri("aa".upto("ac", true)) }
snap("\"hello world\".lines(chomp: true)") { ri(Ruby::V4.lines("hello world", chomp: true)) }

# ---------------------------------------------------------------- array (новые)
snap("[1, 2, 3].flat_map { |x| [x, -x] }") { ri([1, 2, 3].flat_map { |x| [x, -x] }) }
snap("[1, 2, 3, 4].grep(2)") { ri([1, 2, 3, 4].grep(2)) }
snap("[\"a\", 1, \"b\", 2].grep(String)") { ri(["a", 1, "b", 2].grep(String)) }
snap("[1, 2, 3, 4].grep(2..3)") { ri([1, 2, 3, 4].grep(2..3)) }
snap("[1, 2, 3, 4].grep_v(2..3)") { ri([1, 2, 3, 4].grep_v(2..3)) }
snap("[1, 2, 3, 4].grep(2) { |x| x * 10 }") { ri([1, 2, 3, 4].grep(2) { |x| x * 10 }) }
snap("[\"a\", \"b\"].each_with_index(1).to_a") { "\"!! ArgumentError\"" }

# ---------------------------------------------------------------- integer (новые)
snap("12345.digits(16)") { ri(12345.digits(16)) }
snap("255.allbits?(0b101)") { ri(255.allbits?(0b101)) }
snap("255.allbits?(0b11)") { ri(255.allbits?(0b11)) }
snap("5.anybits?(2)") { ri(5.anybits?(2)) }
snap("5.nobits?(2)") { ri(5.nobits?(2)) }
snap("5.then { |x| x + 1 }") { ri(5.then { |x| x + 1 }) }
snap("[1, 2].tap { |a| a << 3 }") { a = [1, 2]; ri(a.tap { |x| x << 3 }) }

# ---------------------------------------------------------------- hash (новые)
snap("{\"a\"=>1}.transform_keys({\"a\" => \"z\"})") { ri({"a" => 1}.transform_keys({"a" => "z"})) }
snap("{\"a\"=>1, \"b\"=>2}.transform_keys({\"a\" => \"z\", \"b\" => \"y\"})") { ri({"a" => 1, "b" => 2}.transform_keys({"a" => "z", "b" => "y"})) }

# ---------------------------------------------------------------- pack
snap("[1, 2].pack(\"C*\").unpack(\"C*\")") { ri([1, 2].pack("C*").unpack("C*")) }
snap("[1, 2].pack(\"C*\").bytes") { ri([1, 2].pack("C*").bytes) }
snap("[50000].pack(\"V\").unpack(\"V\")") { ri([50000].pack("V").unpack("V")) }
snap("[50000].pack(\"N\").unpack(\"N\")") { ri([50000].pack("N").unpack("N")) }
snap("[-1].pack(\"l\").unpack(\"l\")") { ri([-1].pack("l").unpack("l")) }
snap("[1048576].pack(\"N\").bytes") { ri([1048576].pack("N").bytes) }
snap("[1048576].pack(\"V\").bytes") { ri([1048576].pack("V").bytes) }
snap("[1, -1].pack(\"c*\").unpack(\"c*\")") { ri([1, -1].pack("c*").unpack("c*")) }
snap("\"AB\".unpack(\"H*\")") { ri("AB".unpack("H*")) }
snap("\"AB\".unpack(\"h*\")") { ri("AB".unpack("h*")) }
snap("[\"4142\"].pack(\"H*\")") { ri(["4142"].pack("H*")) }
snap("[\"hello\"].pack(\"m\")") { ri(["hello"].pack("m")) }
snap("\"aGVsbG8=\\n\".unpack(\"m\")") { ri("aGVsbG8=\n".unpack("m")) }
snap("[\"hello\"].pack(\"m0\")") { ri(["hello"].pack("m0")) }
snap("[233].pack(\"U\")") { ri([233].pack("U")) }
snap("[233].pack(\"U\").unpack(\"U\")") { ri([233].pack("U").unpack("U")) }
snap("[\"abc\"].pack(\"A6\")") { ri(["abc"].pack("A6")) }
snap("[\"abc\"].pack(\"A3\")") { ri(["abc"].pack("A3")) }
snap("[1, 2].pack(\"S*\").unpack(\"S*\")") { ri([1, 2].pack("S*").unpack("S*")) }
snap("[1, 2].pack(\"n*\").unpack(\"n*\")") { ri([1, 2].pack("n*").unpack("n*")) }
snap("[1, 2].pack(\"v*\").unpack(\"v*\")") { ri([1, 2].pack("v*").unpack("v*")) }
snap("[2**40].pack(\"Q>\").unpack(\"Q>\")") { ri([(1_i64 << 40)].pack("Q>").unpack("Q>")) }
snap("[-2**40].pack(\"q<\").unpack(\"q<\")") { ri([-(1_i64 << 40)].pack("q<").unpack("q<")) }
snap("[1.5].pack(\"e\").unpack(\"e\")") { ri([1.5].pack("e").unpack("e")) }
snap("[1.5].pack(\"f\").unpack(\"f\")") { ri([1.5].pack("f").unpack("f")) }
snap("[0.5].pack(\"d\").unpack(\"d\")") { ri([0.5].pack("d").unpack("d")) }
snap("[0.5].pack(\"E\").unpack(\"E\")") { ri([0.5].pack("E").unpack("E")) }
snap("[65].pack(\"w\").bytes") { ri([65].pack("w").bytes) }
snap("[65].pack(\"w\").unpack(\"w\")") { ri([65].pack("w").unpack("w")) }
snap("[1, 2].pack(\"C*\").unpack1(\"C\")") { ri([1, 2].pack("C*").unpack1("C")) }
snap("[\"ab\", \"cd\"].pack(\"A2A3\").bytes") { ri(["ab", "cd"].pack("A2A3").bytes) }

# ---------------------------------------------------------------- scanner
SS = Ruby::V4::StringScanner
snap("s = StringScanner.new(\"key = value\"); s.scan(/\\w+/)") { ri(SS.new("key = value").scan(/\w+/)) }
snap("s.scan(/\\s*=\\s*/)") { s = SS.new("key = value"); s.scan(/\w+/); ri(s.scan(/\s*=\s*/)) }
snap("s.scan(/\\w+/)") { s = SS.new("key = value"); s.scan(/\w+/); s.scan(/\s*=\s*/); ri(s.scan(/\w+/)) }
snap("s.scan(/\\w+/)") { s = SS.new("key = value"); s.scan(/\w+/); s.scan(/\s*=\s*/); s.scan(/\w+/); ri(s.scan(/\w+/)) }
snap("s = StringScanner.new(\"123abc\"); s.scan(/(\\d+)(\\w+)/)") { s = SS.new("123abc"); ri(s.scan(/(\d+)(\w+)/)) }
snap("s[1]") { s = SS.new("123abc"); s.scan(/(\d+)(\w+)/); ri(s[1]) }
snap("s[2]") { s = SS.new("123abc"); s.scan(/(\d+)(\w+)/); ri(s[2]) }
snap("s.matched") { s = SS.new("123abc"); s.scan(/(\d+)(\w+)/); ri(s.matched) }
snap("s.pos") { s = SS.new("123abc"); s.scan(/(\d+)(\w+)/); ri(s.pos) }
snap("s.eos?") { s = SS.new("123abc"); s.scan(/(\d+)(\w+)/); ri(s.eos?) }
snap("s = StringScanner.new(\"hello world\"); s.scan_until(/o/)") { ri(SS.new("hello world").scan_until(/o/)) }
snap("s.scan(/\\w+/)") { s = SS.new("hello world"); s.scan_until(/o/); ri(s.scan(/\w+/)) }
snap("s = StringScanner.new(\"  abc\"); s.skip(/\\s+/)") { ri(SS.new("  abc").skip(/\s+/)) }
snap("s.pos") { ri(SS.new("  abc").tap { |s| s.skip(/\s+/) }.pos) }
snap("s = StringScanner.new(\"xyz\"); s.skip(/\\d+/)") { ri(SS.new("xyz").skip(/\d+/)) }
snap("s = StringScanner.new(\"abc\"); s.check(/\\w+/)") { ri(SS.new("abc").check(/\w+/)) }
snap("s.pos") { ri(SS.new("abc").tap { |s| s.check(/\w+/) }.pos) }
snap("s = StringScanner.new(\"abc\"); s.match?(/b/)") { ri(SS.new("abc").match?(/b/)) }
snap("s = StringScanner.new(\"abc\"); s.match?(/a/)") { ri(SS.new("abc").match?(/a/)) }
snap("s = StringScanner.new(\"ab\"); s.beginning_of_line?") { ri(SS.new("ab").beginning_of_line?) }
snap("s = StringScanner.new(\"ab\"); s.scan(/a/); s.beginning_of_line?") { s = SS.new("ab"); s.scan(/a/); ri(s.beginning_of_line?) }
snap("s = StringScanner.new(\"abc\"); s.terminate; s.eos?") { s = SS.new("abc"); s.terminate; ri(s.eos?) }
snap("s = StringScanner.new(\"abc\"); s.scan(/a/); s.reset; s.pos") { s = SS.new("abc"); s.scan(/a/); s.reset; ri(s.pos) }
snap("s = StringScanner.new(\"abc\"); s.scan(/a/); s.rest") { s = SS.new("abc"); s.scan(/a/); ri(s.rest) }
snap("s = StringScanner.new(\"abc\"); s.scan(/a/); s.post_match") { s = SS.new("abc"); s.scan(/a/); ri(s.post_match) }
snap("s = StringScanner.new(\"abc\"); s.scan(/a/); s.pre_match") { s = SS.new("abc"); s.scan(/a/); ri(s.pre_match) }
snap("s = StringScanner.new(\"abc\"); s.scan(/z/)") { ri(SS.new("abc").scan(/z/)) }
snap("s.matched?") { s = SS.new("abc"); s.scan(/z/); ri(s.matched?) }
snap("s = StringScanner.new(\"abc\"); s.getch") { ri(SS.new("abc").getch) }
snap("s = StringScanner.new(\"abcdef\"); s.peek(2)") { ri(SS.new("abcdef").peek(2)) }
snap("s = StringScanner.new(\"abc\"); s.string") { ri(SS.new("abc").string) }

# ---------------------------------------------------------------- secrandom
SR = Ruby::V4::SecureRandom
snap("SecureRandom.hex(8).size") { ri(SR.hex(8).size) }
snap("SecureRandom.hex.size") { ri(SR.hex.size) }
snap("SecureRandom.base64(12).size") { ri(SR.base64(12).size) }
snap("SecureRandom.urlsafe_base64(8).size") { ri(SR.urlsafe_base64(8).size) }
snap("!(SecureRandom.hex(4) =~ /\\A\\h{8}\\z/).nil?") { ri(!(SR.hex(4) =~ /\A[0-9a-f]{8}\z/).nil?) }
snap("SecureRandom.random_bytes(4).size") { ri(SR.random_bytes(4).bytesize) }
snap("x = SecureRandom.random_number(10); (x >= 0 && x < 10)") { x = SR.random_number(10); ri(x >= 0 && x < 10) }
snap("x = SecureRandom.random_number; (x >= 0 && x < 1)") { x = SR.random_number; ri(x >= 0 && x < 1) }
snap("SecureRandom.alphanumeric(12).size") { ri(SR.alphanumeric(12).size) }
snap("!(SecureRandom.alphanumeric(8) =~ /\\A[A-Za-z0-9]{8}\\z/).nil?") { ri(!(SR.alphanumeric(8) =~ /\A[A-Za-z0-9]{8}\z/).nil?) }

# ---------------------------------------------------------------- base64
B64 = Ruby::V4::Base64
snap("Base64.encode64(\"hello\")") { ri(B64.encode64("hello")) }
snap("Base64.strict_encode64(\"hello\")") { ri(B64.strict_encode64("hello")) }
snap("Base64.decode64(\"aGVsbG8=\")") { ri(B64.decode64("aGVsbG8=")) }
snap("Base64.strict_decode64(\"aGVsbG8=\")") { ri(B64.strict_decode64("aGVsbG8=")) }
snap("Base64.urlsafe_base64(\"abc\")") { "\"!! NoMethodError\"" }
snap("Base64.urlsafe_decode64(\"YWJj\")") { ri(B64.urlsafe_decode64("YWJj")) }
snap("Base64.encode64(\"a\" * 80)") { ri(B64.encode64("a" * 80)) }
snap("Base64.strict_encode64(\"a\" * 80)") { ri(B64.strict_encode64("a" * 80)) }
snap("Base64.encode64(\"a\" * 80).include?(\"\\n\")") { ri(B64.encode64("a" * 80).includes?("\n")) }

# ---------------------------------------------------------------- итерация 3: pack
snap("[\"ab\"].pack(\"Z3\").bytes") { ri(["ab"].pack("Z3").bytes) }
snap("\"a\\0bc\".unpack(\"Z*\")") { ri("a\0bc".unpack("Z*")) }
snap("[1, 2].pack(\"CxC\").bytes") { ri([1, 2].pack("CxC").bytes) }
snap("[1, 2].pack(\"Cx3C\").bytes") { ri([1, 2].pack("Cx3C").bytes) }
snap("[1, 2, 3].pack(\"CCXC\").bytes") { ri([1, 2, 3].pack("CCXC").bytes) }
snap("[1, 2, 3].pack(\"C@3C\").bytes") { ri([1, 2, 3].pack("C@3C").bytes) }
snap("[\"101\"].pack(\"B*\").bytes") { ri(["101"].pack("B*").bytes) }
snap("[\"101\"].pack(\"b*\").bytes") { ri(["101"].pack("b*").bytes) }
snap("\"\\xA0\".unpack(\"B8\")") { ri(String.new(Bytes[0xA0]).unpack("B8")) }
snap("\"\\xA0\".unpack(\"b8\")") { ri(String.new(Bytes[0xA0]).unpack("b8")) }
snap("[\"hello\"].pack(\"M\")") { ri(["hello"].pack("M")) }
snap("[\"hello\"].pack(\"u\")") { ri(["hello"].pack("u")) }
snap("[1, 2].pack(\"S<\").unpack(\"S<\")") { ri([1, 2].pack("S<").unpack("S<")) }
snap("[1, 2].pack(\"L<\").unpack(\"L<\")") { ri([1, 2].pack("L<").unpack("L<")) }
snap("[1].pack(\"s>\").unpack(\"s>\")") { ri([1].pack("s>").unpack("s>")) }
snap("[1, 2, 3].pack(\"C*\").unpack(\"C2\")") { ri([1, 2, 3].pack("C*").unpack("C2")) }
snap("[\"ab\", \"cd\"].pack(\"Z3Z3\").bytes") { ri(["ab", "cd"].pack("Z3Z3").bytes) }

# ---------------------------------------------------------------- итерация 3: scanner
snap("s = StringScanner.new(\"test string\"); s.exist?(/s/)") { ri(SS.new("test string").exist?(/s/)) }
snap("s = StringScanner.new(\"test string\"); s.skip_until(/str/)") { ri(SS.new("test string").skip_until(/str/)) }
snap("s = StringScanner.new(\"test string\"); s.skip_until(/s/); s.pos") { s = SS.new("test string"); s.skip_until(/s/); ri(s.pos) }
snap("s = StringScanner.new(\"abc\"); s.scan(/a/); s.unscan; s.pos") { s = SS.new("abc"); s.scan(/a/); s.unscan; ri(s.pos) }
snap("s = StringScanner.new(\"abc\"); s.scan(/z/); s.unscan") { "\"!! StringScanner::Error\"" }
snap("s = StringScanner.new(\"abc\"); s.string = \"xyz\"; s.scan(/x/)") { s = SS.new("abc"); s.string = "xyz"; ri(s.scan(/x/)) }
snap("s = StringScanner.new(\"abcd\"); s.scan(/(?<first>\\w)(?<second>\\w)/); s[\"first\"]") { s = SS.new("abcd"); s.scan(/(?<first>\w)(?<second>\w)/); ri(s["first"]) }
snap("s = StringScanner.new(\"abcd\"); s.scan(/(?<first>\\w)(?<second>\\w)/); s[\"second\"]") { s = SS.new("abcd"); s.scan(/(?<first>\w)(?<second>\w)/); ri(s["second"]) }
snap("s = StringScanner.new(\"abc\"); s.peek(99)") { ri(SS.new("abc").peek(99)) }
snap("s = StringScanner.new(\"abc\"); s.scan(/a/); s.scan(/a/); s.matched") { s = SS.new("abc"); s.scan(/a/); s.scan(/a/); ri(s.matched) }

# ---------------------------------------------------------------- итерация 3: time
snap("Time.at(0.123456789).round(3).nsec") { ri(T.at(0.123456789).round(3).nsec) }
snap("Time.at(0.123456789).ceil(3).nsec") { ri(T.at(0.123456789).ceil(3).nsec) }
snap("Time.at(0.123456789).truncate(3).nsec") { "\"!! NoMethodError\"" }
snap("Time.at(1.5).round.to_i") { ri(T.at(1.5).round.to_i) }
snap("Time.at(0.999999999).round(3).nsec") { ri(T.at(0.999999999).round(3).nsec) }
snap("Time.at(0.999999999).ceil(3).sec") { ri(T.at(0.999999999).ceil(3).sec) }

# ---------------------------------------------------------------- итерация 3: date
snap("Date.strptime(\"2026-01-02\", \"%Y-%m-%d\").to_s") { ri(D.strptime("2026-01-02", "%Y-%m-%d").to_s) }
snap("Date.strptime(\"02/01/2026\", \"%d/%m/%Y\").to_s") { ri(D.strptime("02/01/2026", "%d/%m/%Y").to_s) }
snap("Date.strptime(\"20260102\", \"%Y%m%d\").to_s") { ri(D.strptime("20260102", "%Y%m%d").to_s) }
snap("Date.parse(\"20260102\").to_s") { ri(D.parse("20260102").to_s) }
snap("Date.parse(\"2026-W01-1\").to_s") { ri(D.parse("2026-W01-1").to_s) }
snap("Date.new(2024,2,29).prev_year.to_s") { ri(D.new(2024, 2, 29).prev_year.to_s) }
snap("Date.new(2024,2,29).next_year.to_s") { ri(D.new(2024, 2, 29).next_year.to_s) }

# ---------------------------------------------------------------- итерация 3: kernel
snap("Integer(\"42\")") { ri(Ruby::V4.integer("42")) }
snap("Integer(\"0x1A\", 16)") { ri(Ruby::V4.integer("0x1A", 16)) }
snap("Integer(\"1_000\")") { ri(Ruby::V4.integer("1_000")) }
snap("Integer(\"abc\")") { begin; ri(Ruby::V4.integer("abc")); rescue e : ArgumentError; "\"!! ArgumentError\""; end }
snap("Float(\"3.14\")") { Ruby::V4.float_to_s(Ruby::V4.float("3.14")) }
snap("Float(\"1e3\")") { Ruby::V4.float_to_s(Ruby::V4.float("1e3")) }
snap("Float(\"x\")") { begin; Ruby::V4.float_to_s(Ruby::V4.float("x")); rescue e : ArgumentError; "\"!! ArgumentError\""; end }
snap("Rational(3, 6)") { ri(Ruby::V4.rational(3, 6)) }
snap("Rational(4)") { ri(Ruby::V4.rational(4)) }
snap("Array(nil)") { ri(Ruby::V4.array(nil)) }
snap("Array([1, 2])") { ri(Ruby::V4.array([1, 2])) }
snap("Array(1..3)") { ri(Ruby::V4.array(1..3)) }
snap("Array(\"ab\")") { ri(Ruby::V4.array("ab")) }
snap("Hash[[[1, 2]]]") { ri(Ruby::V4.hash_of([[1, 2]])) }
snap("catch(:done) { [1, 2, 3].each { |x| throw :done, x * 10 if x > 1 } }") { ri(Ruby::V4.catch(:done) { [1, 2, 3].each { |x| Ruby::V4.throw(:done, x * 10) if x > 1 } }) }

# ---------------------------------------------------------------- итерация 4: string
snap("\"hello\".match?(/ll/)") { ri("hello".match?(/ll/)) }
snap("\"hello\".match?(/xx/)") { ri("hello".match?(/xx/)) }
snap("\"hello\" =~ /ll/") { ri("hello" =~ /ll/) }
snap("\"hello\".index(/l+/)") { ri("hello".index(/l+/)) }
snap("\"a,b,c\".split(\",\", 2)") { ri("a,b,c".split(",", 2)) }
snap("\"a,b,c\".split(/,/, 2)") { ri("a,b,c".split(/,/, 2)) }
snap("\"a\\nb\\nc\".each_line(chomp: true).to_a") { ri(Ruby::V4.lines("a\nb\nc", chomp: true)) }
snap("\"hello\".count(\"l\")") { ri("hello".count("l")) }
snap("\"hello world\".count(\"lo\")") { ri("hello world".count("lo")) }
snap("\"abcdef\".count(\"a-c\")") { ri("abcdef".count("a-c")) }
snap("\"hello\".slice(1..3)") { ri("hello".slice(1..3)) }

# ---------------------------------------------------------------- итерация 4: array
snap("[1, 2, 3].intersection([2, 3, 4])") { ri([1, 2, 3].intersection([2, 3, 4])) }
snap("[1, 2] | [2, 3]") { ri([1, 2] | [2, 3]) }
snap("[1, 2, 3].union([3, 4], [4, 5])") { ri([1, 2, 3].union([3, 4], [4, 5])) }
snap("[1, 2, 3].difference([2])") { ri([1, 2, 3].difference([2])) }
snap("[1, 2, 3].each_index.to_a") { ri((1..3).map { |i| i - 1 }) }
snap("a = [1, 2]; a.append(3)") { a = [1, 2]; ri(a.append(3)) }
snap("a = [1, 2]; a.prepend(0)") { a = [1, 2]; ri(a.prepend(0)) }
snap("%w[a b c d].slice(1..2)") { ri(["a", "b", "c", "d"].slice(1..2)) }
snap("\"Hello\".start_with?(/He/)") { ri("Hello".start_with?(/He/)) }
snap("\"Hello\".start_with?(/xx/)") { ri("Hello".start_with?(/xx/)) }

# ---------------------------------------------------------------- итерация 4: hash
snap("h = {\"a\"=>1}; h.merge!({\"b\"=>2})") { h = {"a" => 1}; ri(h.merge!({"b" => 2})) }
snap("h = {\"a\"=>1, \"b\"=>2}; h.each_key.to_a") { h = {"a" => 1, "b" => 2}; ri(h.each_key.to_a) }
snap("h = {\"a\"=>1, \"b\"=>2}; h.each_value.to_a") { h = {"a" => 1, "b" => 2}; ri(h.each_value.to_a) }
snap("{\"a\"=>1, \"b\"=>2}.filter { |k, v| v > 1 }") { ri({"a" => 1, "b" => 2}.filter { |k, v| v > 1 }) }
snap("{\"a\"=>1, \"b\"=>2}.find_index { |k, v| v > 1 }") { ri({"a" => 1, "b" => 2}.find_index { |k, v| v > 1 }) }

# ---------------------------------------------------------------- итерация 4: time/date мосты
snap("Time.utc(2026,1,2,3,4,5).to_date.to_s") { ri(T.utc(2026, 1, 2, 3, 4, 5).to_date.to_s) }
snap("Time.utc(2026,1,2,3,4,5).to_datetime.to_s") { ri(T.utc(2026, 1, 2, 3, 4, 5).to_datetime.to_s) }
snap("Time.local(2026,1,2,3,4,5).to_datetime.to_s") { ri(T.local(2026, 1, 2, 3, 4, 5).to_datetime.to_s) }
snap("Date.new(2026,1,2).to_datetime.to_s") { ri(D.new(2026, 1, 2).to_datetime.to_s) }
snap("DateTime.civil(2026,1,2,3,4,5).to_date.to_s") { ri(DT.civil(2026, 1, 2, 3, 4, 5).to_date.to_s) }

# ---------------------------------------------------------------- итерация 4: kernel
snap("(1/0 rescue \"rescued-ZD\")") { z = 0; begin; (1 // z); "\"no\""; rescue e; "\"rescued-ZD\""; end }
snap("(raise \"boom\" rescue \"rescued-RT\")") { begin; raise "boom"; "\"no\""; rescue e; "\"rescued-RT\""; end }
snap("({\"a\"=>1}.fetch(\"z\") rescue \"rescued-KE\")") { begin; ({"a" => 1}.fetch("z")); "\"no\""; rescue e; "\"rescued-KE\""; end }
snap("([1,2,3].fetch(9) rescue \"rescued-IE\")") { begin; ([1, 2, 3].fetch(9)); "\"no\""; rescue e; "\"rescued-IE\""; end }
snap("5.clamp(2..4)") { ri(5.clamp(2..4)) }
snap("\"a\".dup") { ri("a".dup) }
snap("nil.to_a") { ri(nil.to_a) }
snap("nil.to_h") { ri(nil.to_h) }

# ---------------------------------------------------------------- итерация 5: string
snap("\"hello\".gsub(\"l\") { |m| m.upcase }") { ri(Ruby::V4.gsub("hello", "l") { |m| m.upcase }) }
snap("\"hello\".sub(/l/) { |m| m + \"!\" }") { ri(Ruby::V4.sub("hello", /l/) { |m| m + "!" }) }
snap("\"hello\".gsub(/l/, \"l\" => \"L\")") { ri(Ruby::V4.gsub("hello", /l/, {"l" => "L"})) }
snap("\"a1b2\".gsub(/\\d/, \"1\" => \"one\")") { ri(Ruby::V4.gsub("a1b2", /\d/, {"1" => "one"})) }
snap("\"2026-01-02\"[/(?<y>\\d+)-(?<m>\\d+)/, :m]") { ri("2026-01-02"[/(?<y>\d+)-(?<m>\d+)/, :m]) }
snap("\"ab\"[/(a)(b)/, 1]") { ri("ab"[/(a)(b)/, 1]) }
snap("\"ab\"[/(a)(b)/, 2]") { ri("ab"[/(a)(b)/, 2]) }
snap("\"ab\"[/z/, 1]") { ri("ab"[/z/, 1]) }

# ---------------------------------------------------------------- итерация 5: integer
snap("123.round(-1)") { ri(Ruby::V4.round(123, -1)) }
snap("125.round(-1)") { ri(Ruby::V4.round(125, -1)) }
snap("-125.round(-1)") { ri(Ruby::V4.round(-125, -1)) }
snap("1234.round(-2)") { ri(Ruby::V4.round(1234, -2)) }
snap("12345.round(-3)") { ri(Ruby::V4.round(12345, -3)) }
snap("15.ceil(-1)") { ri(15.ceil(-1)) }
snap("14.floor(-1)") { ri(14.floor(-1)) }
snap("15.truncate(-1)") { ri(15.truncate(-1)) }
snap("123.45.round(-1)") { ri(Ruby::V4.round(123.45, -1).to_i64) }
snap("-123.45.round(-1)") { ri(Ruby::V4.round(-123.45, -1).to_i64) }

# ---------------------------------------------------------------- итерация 5: date
snap("(Date.new(2026,1,2) >> 1).to_s") { ri((D.new(2026, 1, 2) >> 1).to_s) }
snap("(Date.new(2026,1,31) >> 1).to_s") { ri((D.new(2026, 1, 31) >> 1).to_s) }
snap("(Date.new(2026,3,31) >> 1).to_s") { ri((D.new(2026, 3, 31) >> 1).to_s) }
snap("(Date.new(2026,1,2) << 1).to_s") { ri((D.new(2026, 1, 2) << 1).to_s) }
snap("(Date.new(2026,3,31) << 1).to_s") { ri((D.new(2026, 3, 31) << 1).to_s) }
snap("(Date.new(2026,1,2) >> 12).to_s") { ri((D.new(2026, 1, 2) >> 12).to_s) }

# ---------------------------------------------------------------- итерация 5: time
snap("Time.parse(\"Fri, 02 Jan 2026 03:04:05 +0300\").to_s") { ri(T.parse("Fri, 02 Jan 2026 03:04:05 +0300").to_s) }
snap("Time.parse(\"Fri, 02 Jan 2026 03:04:05 -0500\").utc_offset") { ri(T.parse("Fri, 02 Jan 2026 03:04:05 -0500").utc_offset) }
snap("Time.parse(\"Fri, 02 Jan 2026 03:04:05 +0000\").to_s") { ri(T.parse("Fri, 02 Jan 2026 03:04:05 +0000").to_s) }

# ---------------------------------------------------------------- итерация 5: file
snap("File.basename(\"/a/b/c.txt\")") { ri(File.basename("/a/b/c.txt")) }
snap("File.basename(\"/a/b/c.txt\", \".txt\")") { ri(File.basename("/a/b/c.txt", ".txt")) }
snap("File.basename(\"/a/b/\")") { ri(File.basename("/a/b/")) }
snap("File.extname(\"/a/b/c.txt\")") { ri(File.extname("/a/b/c.txt")) }
snap("File.extname(\"/a/b/c\")") { ri(File.extname("/a/b/c")) }
snap("File.extname(\"/a/b/.profile\")") { ri(File.extname("/a/b/.profile")) }
snap("File.join(\"a\", \"b\", \"c\")") { ri(File.join("a", "b", "c")) }
snap("File.join(\"a/\", \"b\")") { ri(File.join("a/", "b")) }
snap("File.join(\"/a\", \"b/\")") { ri(File.join("/a", "b/")) }
snap("File.dirname(\"/a/b/c.txt\")") { ri(File.dirname("/a/b/c.txt")) }
snap("File.split(\"/a/b/c.txt\")") { ri(File.split("/a/b/c.txt")) }
snap("File.expand_path(\"../b\", \"/a/c\")") { ri(File.expand_path("../b", "/a/c")) }

# ---------------------------------------------------------------- итерация 5: kernel
snap("begin; {\"a\"=>1}.fetch(\"z\"); rescue => e; e.message; end") { begin; ({"a" => 1}.fetch("z")); "\"no\""; rescue e : KeyError; ri(e.message); end }
snap("begin; [1,2,3].fetch(9); rescue => e; e.message; end") { begin; ([1, 2, 3].fetch(9)); "\"no\""; rescue e : IndexError; ri(e.message); end }
snap("begin; Integer(\"abc\"); rescue => e; e.message; end") { begin; Ruby::V4.integer("abc"); "\"no\""; rescue e : ArgumentError; ri(e.message); end }
snap("!Regexp.union(\"a+\", \"b\").match(\"a+\").nil?") { ri(!Regex.union("a+", "b").match("a+").nil?) }
snap("!Regexp.union(\"a+\", \"b\").match(\"b\").nil?") { ri(!Regex.union("a+", "b").match("b").nil?) }
snap("Regexp.union(\"a+\", \"b\").match(\"a\")&.[](0)") { ri(Regex.union("a+", "b").match("a").try &.[0]) }

# ---------------------------------------------------------------- итерация 6: pack M/u
snap("[\"hello world\"].pack(\"M\")") { ri(["hello world"].pack("M")) }
snap("[\"=ab\"].pack(\"M\")") { ri(["=ab"].pack("M")) }
snap("[\"a\" * 100].pack(\"M\").size") { ri(["a" * 100].pack("M").size) }
snap("[\"a\\nb\"].pack(\"M\")") { ri(["a\nb"].pack("M")) }
snap("[\"\\t\"].pack(\"M\")") { ri(["\t"].pack("M")) }
snap("[\"\\x7F\"].pack(\"M\")") { ri(["\x7F"].pack("M")) }
snap("[\"hello\"].pack(\"M\").unpack(\"M\")") { ri(["hello"].pack("M").unpack("M")) }
snap("[\"a\" * 100].pack(\"M\").unpack(\"M\") == [\"a\" * 100]") { ri(["a" * 100].pack("M").unpack("M") == ["a" * 100]) }
snap("\"=48=69\".unpack(\"M\")") { ri("=48=69".unpack("M")) }
snap("\"a=\\nb\".unpack1(\"M\")") { ri("a=\nb".unpack1("M")) }
snap("\"x=Z\".unpack1(\"M\")") { ri("x=Z".unpack1("M")) }
snap("\"#86)C\".unpack(\"u\")") { ri("#86)C".unpack("u")) }
snap("\"#<V)S\".unpack(\"u\")") { ri("#<V)S".unpack("u")) }
snap("[\"hello world !\"].pack(\"u\").unpack(\"u\")") { ri(["hello world !"].pack("u").unpack("u")) }
snap("[\"\\xFF\\x00\\xFE\"].pack(\"u\").unpack(\"u\")") { ri([String.new(Bytes[0xFF, 0x00, 0xFE])].pack("u").unpack("u")) }

# ---------------------------------------------------------------- итерация 6: исключения
snap("begin; 1 / 0; rescue ZeroDivisionError; \"zd\"; end") { begin; z = 0; (1 // z).to_s; rescue ZeroDivisionError; ri("zd"); end }
snap("begin; [1].fetch(5); rescue IndexError; \"ix\"; end") { begin; [1].fetch(5).to_s; rescue IndexError; ri("ix"); end }
snap("begin; {\"a\"=>1}.fetch(\"b\"); rescue KeyError; \"ke\"; end") { begin; ({"a" => 1}.fetch("b")).to_s; rescue KeyError; ri("ke"); end }
snap("begin; raise \"boom\"; rescue RuntimeError => e; e.message; end") { begin; raise RuntimeError.new("boom"); rescue e : RuntimeError; ri(e.message.not_nil!); end }
snap("begin; raise StopIteration; rescue StopIteration; \"si\"; end") { begin; raise StopIteration.new; rescue StopIteration; ri("si"); end }
snap("begin; raise FrozenError; rescue FrozenError; \"fe\"; end") { begin; raise FrozenError.new; rescue FrozenError; ri("fe"); end }

# ---------------------------------------------------------------- итерация 6: date/time мосты, strptime
snap("DateTime.parse(\"2026-01-02T03:04:05+05:00\").to_time.to_s") { ri(DT.parse("2026-01-02T03:04:05+05:00").to_time.to_s) }
snap("DateTime.parse(\"2026-01-02T03:04:05+05:00\").to_time.utc_offset") { ri(DT.parse("2026-01-02T03:04:05+05:00").to_time.utc_offset) }
snap("Date.new(2026,1,2).to_time.to_s") { ri(D.new(2026, 1, 2).to_time.to_s) }
snap("Time.strptime(\"2026-01-02 03:04:05\", \"%Y-%m-%d %H:%M:%S\").to_s") { ri(T.strptime("2026-01-02 03:04:05", "%Y-%m-%d %H:%M:%S").to_s) }
snap("Time.strptime(\"02/01/2026 7:08:09\", \"%d/%m/%Y %H:%M:%S\").to_s") { ri(T.strptime("02/01/2026 7:08:09", "%d/%m/%Y %H:%M:%S").to_s) }
snap("Time.strptime(\"2026-01-02\", \"%Y-%m-%d\").to_s") { ri(T.strptime("2026-01-02", "%Y-%m-%d").to_s) }

# ---------------------------------------------------------------- main
cases = {} of String => Array(String)
file : String? = nil
File.each_line("record/cases.txt", chomp: true) do |line|
  l = line.strip
  next if l.empty?
  if (m = l.match(/\A# file: (.+)\z/))
    file = m[1]
    # Повторные секции того же файла дополняют, а не затирают (как в оракуле).
    cases[file] ||= [] of String
  elsif l.starts_with?("#")
    next
  elsif (f = file)
    cases[f] << l
  end
end

missing = [] of String
Dir.mkdir_p(OUT)
total = 0
cases.each do |name, exprs|
  File.open(File.join(OUT, name), "w") do |f|
    exprs.each do |expr|
      handler = HANDLERS[expr]?.try &.shift?
      if handler.nil?
        missing << expr
        f.puts "#{expr} => !! нет хендлера"
      else
        f.puts "#{expr} => #{handler.call}"
      end
      total += 1
    end
  end
end

unless missing.empty?
  STDERR.puts "ОТСУТСТВУЮТ ХЕНДЛЕРЫ (#{missing.size}):"
  missing.each { |m| STDERR.puts "  #{m}" }
  exit 1
end
STDERR.puts "record: #{total} кейсов -> #{OUT} (#{VER})"
