# ruby.cr — слой совместимости с Ruby stdlib для Crystal

Портирует API stdlib Ruby в Crystal 1:1 там, где это возможно: версионные
пространства `Ruby::V4` (снято с ruby 4.0.4) и `Ruby::V3` (ruby 3.4.5),
плюс аддитивные переоткрытия базовых типов Crystal недостающими методами
Ruby. Паритет 1:1 сверяется оракулом [twinshot](https://rubygems.org/gems/twinshot):
слепки с настоящего Ruby против зеркальных слепков через ruby.cr
(**868 кейсов × 2 версии, бит-в-бит: 34/34**).

## Устройство

```
src/ruby.cr              — входная точка (require)
src/ruby/mt19937.cr      — MT19937, бит-в-бит совместим с Random Ruby
src/ruby/random.cr       — Ruby::V4::Random (rand/bytes/srand, float-диапазоны)
src/ruby/time.cr         — Ruby::V4::Time (strftime c %:z, subsec, parse, to_a)
src/ruby/rational.cr     — Ruby::V4::Rational (subsec: точный Rational из double)
src/ruby/date.cr         — Ruby::V4::Date/DateTime (JD, ISO-недели, реформа 1582)
src/ruby/pack.cr         — Array#pack / String#unpack / unpack1
src/ruby/strscan.cr      — Ruby::V4::StringScanner
src/ruby/base64.cr       — Ruby::V4::Base64 (encode64/strict/urlsafe)
src/ruby/securerandom.cr — Ruby::V4::SecureRandom (hex/base64/alphanumeric/…)
src/ruby/struct.cr       — Ruby.struct_def-макрос
src/ruby/kernel.cr       — Ruby::V4.format/sprintf (%p, %<имя>, %{имя}, %#o)
src/ruby/inspect.cr      — Ruby::V4.inspect и хелперы (float_to_s, round, …)
src/ruby/core_ext/*.cr   — аддитивные переоткрытия String/Int/Float/Array/Hash/Set/Range

oracle/record.rb         — снятие слепков с настоящего Ruby (оракул)
record/record.cr         — зеркальные слепки через ruby.cr
record/cases.txt         — общий список кейсов (868, 17 файлов)
bin/record-ruby|crystal  — обёртки съёмки слепков v3/v4
```

## Использование

```crystal
require "ruby"   # зависимости кристального проекта: ruby_cr

Ruby::V4::Time.now
Ruby::V4::Time.gm(2026, 1, 2, 3, 4, 5).strftime("%^A %F")
Ruby::V4::Date.new(2026, 1, 2).cweek          # => 1
Ruby::V4::Random.new(42).rand                 # => 0.3745401188473625 (как Ruby)
[1,2,3,4,5].shuffle(Ruby::V4::Random.new(42)) # => [2, 5, 3, 1, 4]
Ruby::V4.format("%<a>05.1f", a: 3.14159)      # => "003.1"

Ruby.struct_def Point, x, y
Point.new(1, 2).to_s                          # => "#<struct Point x=1, y=2>"

# аддитивные методы на базовых типах:
"zz".succ          # => "aaa"
"0x10".hex         # => 16
"abc".casecmp?("ABC")                          # => true
[1,2,3].filter_map { |x| x.even? ? x : nil }  # => [2]
[1,2,3,4].grep(2..3)                           # => [2, 3]
[1,2,3,4,5].sample(Ruby::V4::Random.new(42))   # => 4
({"a" => 1, "b" => 2}).except("a")            # => {"b" => 2}
Set{1, 2}.subset?(Set{1, 2, 3})               # => true
(1..3).overlap?(3..5)                         # => true
[50000].pack("V").unpack("V")                  # => [50000]
"AB".unpack("H*")                              # => ["4142"]

# new модули:
s = Ruby::V4::StringScanner.new("key = value")
s.scan(/\w+/)                                  # => "key"
Ruby::V4::Base64.encode64("hello")              # => "aGVsbG8=\n"
Ruby::V4::SecureRandom.hex(8).size              # => 16
Ruby::V4::Time.at(0.5).subsec.inspect           # => "(1/2)"

# kernel-функции (Integer()/Float() — lowercase):
Ruby::V4.integer("1_000")                       # => 1000
Ruby::V4.rational(3, 6).inspect                 # => "(1/2)"
Ruby::V4.array(1..3)                            # => [1, 2, 3]
Ruby::V4.catch(:done) { |tag| [1, 2].each { |x| Ruby::V4.throw(tag, x) if x > 1 } }  # => 2
```

## V3 против V4

На снятой батарее различия версий Ruby касаются только Set:

|                        | Ruby 3.4            | Ruby 4.0     |
|------------------------|---------------------|--------------|
| `Set#inspect`/`to_s`   | `#<Set: {1, 2}>`    | `Set[1, 2]`  |
| порядок `Set#^`        | other\self → self\other | self\other → other\self |

`Ruby::V3` повторяет `Ruby::V4` (алиасы Time/Date/Random/Struct/format) со
своим рендером Set (`Ruby::V3.inspect`, `Ruby::V3.set_xor`).

## Сверка с Ruby (twinshot)

```sh
make compare   # снимает 4 деревa слепков и сверяет: ruby-v{3,4} vs crystal-v{3,4}
make spec      # юнит-тесты Crystal
make review    # twinshot review all
```

Оракул снимается с настоящих руби:
`~/.rvm/rubies/ruby-3.4.5` и `~/.rvm/rubies/ruby-4.0.4` (TZ=Europe/Moscow).
Добавить/расширить кейсы — правь `record/cases.txt` и оба зеркала
(`oracle/record.rb` читает тот же файл; `record/record.cr` хранит хендлеры).

## Ограничения совместимости

Полный список отличий stdlib Ruby от Crystal и сознательных отклонений —
в [DIFFERENCES.md](DIFFERENCES.md).
