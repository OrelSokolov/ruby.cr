# Отличия stdlib Ruby от Crystal и отклонения ruby.cr

Составлено эмпирически: батарея из 868 кейсов (`record/cases.txt`, 17 файлов)
снята с ruby 3.4.5 и 4.0.4 и сверена с Crystal 1.21 через ruby.cr
(twinshot, 34/34). Значения в скобках — как решено в ruby.cr.

## 1. Уже совместимо (сверено оракулом)

Неожиданно много базового совпадает бит-в-бит, портировать не нужно:

- `Integer#%`, `modulo`/`divmod`/`remainder` — семантика floor-деления совпадает
  (`-7 % 3 == 2` в обоих).
- `sprintf`: `%d %x %X %#x %#b %e %E %f %g %.Nf`, флаги `- + 0 # пробел`,
  позиционные `%3$s`, `%.0f`-банкинг, `String#%` — идентичны.
- Формат `Hash#inspect` — Ruby 3.4+ перешёл на `{"a" => 1}` как в Crystal.
- `Float#infinite?` возвращает `1/-1/nil` (не bool) — как в Crystal.
- `Array#tally`, `product`-порядок, `each_combination`/`each_permutation`
  порядок, `dig`, `rotate`, `bsearch`, `sort`-стабильность на батарее.
- `Int#digits`, `bit_length`, `gcd/lcm`, `upto/downto/step`, `clamp`,
  `String#tr/squeeze/delete/strip/center(Char)/chomp`.
- `Range#step` (включая Float и Char), `sum`, `first(n)` на безконечном.
- `File.basename` (с суффиксом), `extname` (`.profile` → ""), `join`,
  `dirname`, `expand_path(base)` — уже совместимы (сверено батареей file.txt).
- Set: `| & - ^ ==` (порядок `^` совпадает с Ruby 4).

## 2. Отсутствовало в Crystal — добавлено аддитивно (core_ext)

`Array#filter_map/combination/permutation/max(n)/min(n)/chunk_while/slice_when/
assoc/rassoc/values_at(Range)/shuffle(Ruby::V4::Random)/sample[ (n,) random:]/
flatten(depth)/drop_while/take_while/fetch(1 арг)/inject/grep/grep_v`,
`Enumerable#inject`,
`String#succ`(был?)`/hex/oct/ord/getbyte/setbyte/byteslice/slice/swapcase/
start_with?(*args)/start_with?(Regex)/end_with?(*args)/center(len,String)/
ljust/rjust(String)/concat/prepend/delete_prefix/delete_suffix/casecmp/
casecmp?/upto/match?(Regex)/=~(Regex)/slice(Range)/count(*наборы)`,
`Int#modulo/pow(m,mod)/gcdlcm/between?/[](bit)/allbits?/anybits?/nobits?`,
`Float#floor(digits)/ceil(digits)/truncate(digits)`,
`Object#then`, `Nil#to_a/to_h`,
`Array#intersection(*)/union(*)/difference(*)/append/prepend/slice(Range)`,
`Hash#except/slice/key/filter_map/sum(&)/fetch(key)/sort_by/min_by/max_by/
sort/transform_keys(Hash)/filter/find_index`,
`Set#subset?/superset?/<=/</disjoint?/intersect?/sort`,
`Range#overlap?/===/cover?`,
`Array#pack(fmt)`/`String#unpack(fmt)`/`unpack1` (`C c S s L l V v N n Q q J`
с `< >`, `e E f d g G`, `U w m m0 H h a A Z B b M u x X @`, повторители
`*`/число),
`Int#ceil/floor/truncate(digits<0)`, `File.split`,
`String#[](Regex, Int|Symbol)` (nil без матча — Crystal бросает),
`Time.strptime` (`%Y %y %m %d %H %M %S`, жадные цифры без ведущего нуля),
`Date#to_time` (локальная полночь) и `DateTime#to_time` (сохраняет офсет),
исключения `ZeroDivisionError` (алиас `DivisionByZeroError`), `StopIteration`
(< IndexError, с `result`), `FrozenError` (< RuntimeError).

Kernel-функции (lowercase — `Integer()` в Crystal не выражается):
`Ruby::V4.integer/float/rational/array/hash_of` — строгие `Integer()/Float()`
с префиксами и подчёркиваниями, `Rational()`, `Array()`, `Hash[[…]]`;
`Ruby::V4.catch/throw` через исключение-сигнал;
`Ruby::V4.round(Int, digits)` — half-up для отрицательной точности
(Crystal `round(digits)` — half-to-even);
`Ruby::V4.sub/gsub(pattern) { |строка| }` и `gsub(pattern, Hash)`
(Crystal-блок получает String c 1.21, но Hash-варианта нет).

## 3. Конфликтующие методы (не переопределяем — хелперы Ruby::V4.*)

| Ruby | Crystal | ruby.cr |
|------|---------|---------|
| `Float#round` — half **up** (2.5→3), 0 знаков → Integer | `ties_even` (2.5→2), всегда Float | `Ruby::V4.round(x, digits, half:)` |
| `"a\nb".lines` → `["a\n","b"]` (с \n); `lines(chomp: true)` | `["a","b"]` | `Ruby::V4.lines(s[, chomp])` |
| `"x".scan(re)` → `[String]` | `[MatchData]` | `Ruby::V4.scan` |
| `[1,2,3].zip([4,5])` → паддинг nil | `IndexError` | `Ruby::V4.zip` |
| `10.chr` → `"\n"` (String) | `'\n'` (Char) | `Ruby::V4.chr` |
| `Set#add?` → self/nil | `Bool` | `Ruby::V4.set_add?` |
| `Float#to_s`: `1.0e-05` (2 цифры экспоненты) | `1.0e-5` | `Ruby::V4.float_to_s` |
| `Hash#min/max/min_by/find` → `[k,v]`-массив | Tuple `{"a",1}` | `.to_a` / `Ruby::V4.inspect` (Tuple→Array) |
| `Kernel#format`: `%p`, `%<имя>…`, `%{имя}` | нет `%p`/именованных; `%#o`→`0o` вместо `0` | `Ruby::V4.format` |
| `String#each_char.first(3)` | итератор | `.chars.first(3)` |
| `Set#inspect`/`to_s` | `Set{1, 2}` | `Ruby::V3/V4.set_inspect` (версии различаются!) |

## 4. Системные различия (не решается на уровне слоя)

- **Symbol отсутствует в Crystal.** `Point.members` → `["x","y"]` вместо
  `[:x,:y]`; `Struct#to_h` — String-ключи. Для вывода «как Ruby» —
  `Ruby::V4.sym_array_inspect/sym_hash_inspect`.
- **Enumerator/ленивость:** Ruby-методы, возвращающие Enumerator
  (`10.times`, `Date#step`, `each_slice` без блока), в ruby.cr без блока
  возвращают Array (документированное отклонение).
- **Гетерогенные массивы:** рекурсивные союзы типов невыразимы —
  `flatten(depth)` боксирует в `Ruby::V4::Any` (см. src/ruby/inspect.cr).
- **Мутация строк:** `String#concat/prepend` в Crystal возвращают новую
  строку (строки неизменяемые); bang-методы Ruby не портируются.
- **Time.parse/Date.parse** покрывают подмножество форматов
  (ISO-8601 с `±HH:MM`/`±HHMM`/`Z`, httpdate, слэш-даты, имена месяцев,
  дата без времени, ISO basic `20260102`, ISO week `2026-W01-1`;
  `Date.strptime` — `%Y %y %m %d`) — не полный набор `Date._parse`.
- **Бинарные строки:** `SecureRandom.random_bytes(n)` возвращает Crystal
  String; `#size` считает символы UTF-8, а Ruby — байты: для бинарных
  данных используйте `#bytesize`. Кодировки Ruby не моделируются:
  `unpack("M"/"u"/"m")` в Ruby возвращает ASCII-8BIT-строки (inspect
  эскейпит байты ≥ 0x80, включая валидный UTF-8: `"\xC3\xA9"`), в ruby.cr
  строка байт-в-байт та же, но `Ruby::V4.inspect` рендерит валидный
  UTF-8 как символы; для строк с NUL — побайтовый Ruby-рендер (`\x00`,
  не Crystal `\u0000`).

## 5. Отличия Ruby 3.4 → 4.0 (эмпирика на батарее)

На снятой поверхности (702 кейса) различия только в Set:

- `Set#inspect`/`to_s`: `#<Set: {1, 2}>` → `Set[1, 2]`
- `Set#^`: порядок элементов изменился на self\other → other\self

Поэтому `Ruby::V3` — алиасы `Ruby::V4` + собственный рендер Set.

## 6. Что пришлось реализовать с нуля

- **MT19937** с точным сидированием Ruby: `|seed| < 2^32` → `init_genrand`,
  иначе `init_by_array` LE-словами с отбрасыванием ведущего слова `1`
  (verified против `Random.new(2**64)`); выборки float (два 32-битных слова,
  включая `int_pair_to_real_inclusive` для inclusive float-диапазонов),
  limited-rand с маской и повтором (32- и 64-битные диапазоны), `bytes`,
  `srand`, Fisher-Yates `shuffle` в порядке `rb_ary_shuffle`, `sample`/
  `sample(n)` в порядке `rb_ary_sample` (сжатие индексов).
- **Time**: собственный strftime (флаги `- _ ^ 0 :`, `%N/%L/%U/%W/%V/%G/%j/%C/
  %e/%k/%l/%P/%:z/%::z`, композиции `%F %T %D %R %r %c %x %X`, буквальный
  пропуск неизвестных директив), наносекунды из Float через BigFloat (совпадает
  с рациональной интерпретацией double в Ruby: `0.123456789 → 123456788`),
  `subsec` — точный `Rational` из битов double, локальный `Time.at`,
  `at(sec, frac, unit)`, зона-аббревиатура (`zone`/`%Z`: MSK/UTC/nil для
  фиксированных офсетов), `rfc2822` с `-0000`.
- **Date/DateTime** — арифметика на JD с реформой 1582-10-15 (Date::ITALY),
  ISO-недели (алгоритм «четверга»), `next_month` с клампингом дня,
  операторы `>>`/`<<` (месячная арифметика Ruby),
  отрицательные годы (`-0001-01-01` — знак отдельно от `%04d`).
- **Rational** (`Ruby::V4::Rational`) — num/den на Int64, точное построение
  из битов Float64 (`0.123456789 → (8895999182988127/72057594037927936)`).
- **Pack** (`Ruby::V4::Pack`) — директивы `C c S s L l V v N n Q q J P`
  с endianness-модификаторми `< >`, float `e E f d g G`, `U` (UTF-8),
  `w` (BER), `m`/`m0` (base64 с переносом 60), `H h` (hex), `a A Z` (строки
  с паддингом/NUL), `B b` (биты MSB/LSB), `M` (quoted-printable), `u`
  (uuencode с 4-символьными группами), позиционные `x X @`, повторители
  `*`/число/многократные директивы.
- **StringScanner** (`Ruby::V4::StringScanner`) — scan (якорь на pos),
  scan_until, skip/skip_until, check, match?, exist?, getch, peek,
  rest/pre_match/post_match, `[]` по номерам и именованным группам,
  terminate/reset/unscan (с `StringScanner::Error`), `string=`.
- **Base64** (`Ruby::V4::Base64`) — encode64 (перенос 60), strict_*,
  urlsafe_*; **SecureRandom** (`Ruby::V4::SecureRandom`) — hex/base64/
  urlsafe_base64/random_bytes/random_number/alphanumeric поверх
  `Random::Secure`.
