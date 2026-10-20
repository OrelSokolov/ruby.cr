# ruby.cr — Ruby stdlib compatibility layer for Crystal

Ports the Ruby stdlib API to Crystal 1:1 wherever possible: versioned
namespaces `Ruby::V4` (captured from ruby 4.0.4) and `Ruby::V3` (ruby 3.4.5),
plus additive reopenings of Crystal core types with missing Ruby methods.
1:1 parity is verified by the [twinshot](https://rubygems.org/gems/twinshot)
oracle: snapshots taken from real Ruby compared against mirror snapshots
through ruby.cr (**868 cases × 2 versions, bit-for-bit: 34/34**).

## Layout

```
src/ruby.cr              — entry point (require)
src/ruby/mt19937.cr      — MT19937, bit-for-bit compatible with Ruby's Random
src/ruby/random.cr       — Ruby::V4::Random (rand/bytes/srand, float ranges)
src/ruby/time.cr         — Ruby::V4::Time (strftime with %:z, subsec, parse, to_a)
src/ruby/rational.cr     — Ruby::V4::Rational (subsec: exact Rational from double)
src/ruby/date.cr         — Ruby::V4::Date/DateTime (JD, ISO weeks, 1582 reform)
src/ruby/pack.cr         — Array#pack / String#unpack / unpack1
src/ruby/strscan.cr      — Ruby::V4::StringScanner
src/ruby/base64.cr       — Ruby::V4::Base64 (encode64/strict/urlsafe)
src/ruby/securerandom.cr — Ruby::V4::SecureRandom (hex/base64/alphanumeric/…)
src/ruby/struct.cr       — Ruby.struct_def macro
src/ruby/kernel.cr       — Ruby::V4.format/sprintf (%p, %<name>, %{name}, %#o)
src/ruby/inspect.cr      — Ruby::V4.inspect and helpers (float_to_s, round, …)
src/ruby/core_ext/*.cr   — additive reopenings of String/Int/Float/Array/Hash/Set/Range

oracle/record.rb         — taking snapshots from real Ruby (the oracle)
record/record.cr         — mirror snapshots through ruby.cr
record/cases.txt         — shared case list (868, 17 files)
bin/record-ruby|crystal  — wrapper scripts for capturing v3/v4 snapshots
```

## Usage

```crystal
require "ruby"   # crystal project dependency: ruby_cr

Ruby::V4::Time.now
Ruby::V4::Time.gm(2026, 1, 2, 3, 4, 5).strftime("%^A %F")
Ruby::V4::Date.new(2026, 1, 2).cweek          # => 1
Ruby::V4::Random.new(42).rand                 # => 0.3745401188473625 (like Ruby)
[1,2,3,4,5].shuffle(Ruby::V4::Random.new(42)) # => [2, 5, 3, 1, 4]
Ruby::V4.format("%<a>05.1f", a: 3.14159)      # => "003.1"

Ruby.struct_def Point, x, y
Point.new(1, 2).to_s                          # => "#<struct Point x=1, y=2>"

# additive methods on core types:
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

# new modules:
s = Ruby::V4::StringScanner.new("key = value")
s.scan(/\w+/)                                  # => "key"
Ruby::V4::Base64.encode64("hello")              # => "aGVsbG8=\n"
Ruby::V4::SecureRandom.hex(8).size              # => 16
Ruby::V4::Time.at(0.5).subsec.inspect           # => "(1/2)"

# kernel functions (Integer()/Float() — lowercase):
Ruby::V4.integer("1_000")                       # => 1000
Ruby::V4.rational(3, 6).inspect                 # => "(1/2)"
Ruby::V4.array(1..3)                            # => [1, 2, 3]
Ruby::V4.catch(:done) { |tag| [1, 2].each { |x| Ruby::V4.throw(tag, x) if x > 1 } }  # => 2
```

## V3 vs V4

Across the captured battery, Ruby version differences only affect Set:

|                        | Ruby 3.4            | Ruby 4.0     |
|------------------------|---------------------|--------------|
| `Set#inspect`/`to_s`   | `#<Set: {1, 2}>`    | `Set[1, 2]`  |
| `Set#^` order          | other\self → self\other | self\other → other\self |

`Ruby::V3` mirrors `Ruby::V4` (aliases for Time/Date/Random/Struct/format) with
its own Set rendering (`Ruby::V3.inspect`, `Ruby::V3.set_xor`).

## Parity checking against Ruby (twinshot)

```sh
make compare   # captures 4 snapshot trees and compares them: ruby-v{3,4} vs crystal-v{3,4}
make spec      # Crystal unit tests
make review    # twinshot review all
```

The oracle is captured from real rubies:
`~/.rvm/rubies/ruby-3.4.5` and `~/.rvm/rubies/ruby-4.0.4` (TZ=Europe/Moscow).
To add or extend cases, edit `record/cases.txt` and both mirrors
(`oracle/record.rb` reads the same file; `record/record.cr` holds the handlers).

## Compatibility limitations

For the full list of Ruby stdlib vs Crystal differences and deliberate
deviations, see [DIFFERENCES.md](DIFFERENCES.md).
