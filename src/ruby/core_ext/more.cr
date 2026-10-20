# Новые core_ext-методы итерации 2 (Ruby-совместимость):
# String#casecmp/casecmp?/upto, Int#allbits?/anybits?/nobits?,
# Object#then (если нет в stdlib), Enumerable#grep/grep_v (+блок),
# Hash#transform_keys(Hash), Ruby::V4.lines(s, chomp:).

class String
  # Ruby casecmp: сравнение ASCII-case-insensitive → -1/0/1.
  def casecmp(other : String) : Int32
    a = downcase(Unicode::CaseOptions::ASCII)
    b = other.downcase(Unicode::CaseOptions::ASCII)
    a <=> b
  end

  def casecmp?(other : String) : Bool
    casecmp(other) == 0
  end

  # Ruby String#upto: итерация succ до max (exclusive — без последнего).
  def upto(max : String, exclusive : Bool = false, &block : String -> _) : Nil
    s = self
    while s.size <= max.size && (s <=> max) <= 0
      break if exclusive && s == max
      yield s
      break if s == max
      s = s.succ
    end
  end

  def upto(max : String, exclusive : Bool = false) : Array(String)
    out = [] of String
    upto(max, exclusive) { |s| out << s }
    out
  end
end

struct Int
  def allbits?(mask : Int) : Bool
    (self & mask) == mask
  end

  def anybits?(mask : Int) : Bool
    (self & mask) != 0
  end

  def nobits?(mask : Int) : Bool
    (self & mask) == 0
  end
end

class String
  # Ruby String#match? / =~ / slice(Range) / count(наборы) / start_with?(Regex).
  def match?(other : Regex) : Bool
    !self.match(other).nil?
  end

  def =~(other : Regex) : Int32?
    m = other.match(self)
    m ? m.begin(0) : nil
  end

  def slice(range : Range(Int, Int?)) : String
    self[range]
  end

  # start_with? с регуляркой (матч в начале строки).
  def start_with?(pattern : Regex) : Bool
    m = pattern.match(self)
    !m.nil? && m.begin(0) == 0
  end

  # Ruby String#count(*наборы): набор символов с диапазонами a-z и
  # отрицанием ^; несколько аргументов — пересечение наборов.
  def count(*sets : String) : Int32
    final = Ruby.parse_char_set(sets[0])
    sets.each_with_index do |s, i|
      final &= Ruby.parse_char_set(s) if i > 0
    end
    each_char.count { |c| final.includes?(c) }
  end
end

module Ruby
  extend self

  # Разбор набора символов Ruby ("a-c0-9", "^x") в Set(Char).
  def parse_char_set(s : String) : Set(Char)
    negate = s.starts_with?('^')
    s = s[1..] if negate
    set = Set(Char).new
    i = 0
    chars = s.chars
    while i < chars.size
      if i + 2 < chars.size && chars[i + 1] == '-' && chars[i] != '\\'
        (chars[i]..chars[i + 2]).each { |c| set << c }
        i += 3
      else
        set << chars[i]
        i += 1
      end
    end
    if negate
      full = Set(Char).new
      (' '..'~').each { |c| full << c unless set.includes?(c) }
      full
    else
      set
    end
  end
end

module Ruby
  module V4
    extend self

    # sub/gsub с блоком Ruby: блок получает строку матча. В Crystal 1.21
    # gsub(Regex)/gsub(String) уже передают String — просто транслируем.
    def sub(s : String, pattern : Regex | String, &block : String -> _)
      done = false
      s.gsub(pattern) do |m|
        if done
          m.to_s
        else
          done = true
          yield m.to_s
        end
      end
    end

    def gsub(s : String, pattern : Regex | String, &block : String -> _)
      s.gsub(pattern) { |m| yield m.to_s }
    end

    # gsub с Hash: отсутствующий ключ → пустая строка (как в Ruby).
    def gsub(s : String, pattern : Regex | String, hash : Hash)
      s.gsub(pattern) { |m| hash[m.to_s]?.try(&.to_s) || "" }
    end

    # Integer#round(digits) Ruby: half-up (away from zero) — у Crystal
    # round(digits) half-to-even, семантику ядра не меняем.
    def round(x : Int, digits : Int = 0, half : Symbol = :up)
      return x if digits >= 0
      factor = (10 ** -digits).to_i64
      sign = x < 0 ? -1_i64 : 1_i64
      n = x.abs
      q = n // factor
      r = n.remainder(factor)
      if half == :up && r * 2 >= factor
        q += 1
      end
      sign * q * factor
    end
  end
end

class String
  # "s"[re, :group] — по имени группы (Symbol; String-вариант в Crystal есть).
  def [](pattern : Regex, group : Symbol) : String?
    m = pattern.match(self)
    m ? m[group.to_s]? : nil
  end

  # Ruby: "ab"[/z/, 1] → nil (Crystal бросает NilAssertionError).
  def [](pattern : Regex, group : Int) : String?
    m = pattern.match(self)
    m ? m[group]? : nil
  end
end

struct Int
  # ceil/floor/truncate с отрицательной точностью (15.ceil(-1) → 20).
  def ceil(digits : Int)
    return self if digits >= 0
    factor = (10 ** -digits)
    q, r = self // factor, remainder(factor)
    q * factor + (r > 0 ? factor : 0)
  end

  def floor(digits : Int)
    return self if digits >= 0
    factor = (10 ** -digits)
    self // factor * factor
  end

  def truncate(digits : Int)
    return self if digits >= 0
    factor = (10 ** -digits)
    (abs // factor * factor) * (self < 0 ? -1 : 1)
  end
end

class File
  # Ruby File.split → [dirname, basename].
  def self.split(path : String) : Tuple(String, String)
    {dirname(path), basename(path)}
  end
end

class Object
  # Ruby Object#then (yield self) — в новых версиях Crystal уже есть.
  def then(&block : self -> _)
    yield self
  end
end

class Array
  # Ruby set-операции: intersection/union/difference с несколькими аргументами.
  def intersection(*others : Array) : Array(T)
    out = self & others[0]
    others.each_with_index do |o, i|
      out &= o if i > 0
    end
    out
  end

  def union(*others : Array) : Array(T)
    out = dup
    others.each do |o|
      o.each { |v| out << v unless out.includes?(v) }
    end
    out
  end

  def difference(*others : Array) : Array(T)
    out = dup
    others.each do |o|
      o.each { |v| out.delete(v) }
    end
    out
  end

  def append(*values : T) : self
    push(*values)
  end

  def prepend(*values : T) : self
    unshift(*values)
  end

  # Ruby Array#slice(range): ["a","b","c"].slice(1..2) → ["b","c"].
  def slice(range : Range(Int, Int?)) : Array(T)
    self[range]
  end
end

class Hash
  # Ruby Hash#filter — алиас select; find_index — индекс первой пары.
  def filter(&block : K, V -> _)
    self.select { |k, v| yield k, v }
  end

  def find_index(&block : K, V -> _)
    idx = 0
    each do |k, v|
      return idx if yield k, v
      idx += 1
    end
    nil
  end
end

struct Nil
  # nil.to_a / nil.to_h как в Ruby.
  def to_a : Array(Nil)
    [] of Nil
  end

  def to_h : Hash(Nil, Nil)
    {} of Nil => Nil
  end
end

module Ruby
  module V4
    extend self

    # pattern === value для grep: класс → is_a?, Range → cover?, Regex →
    # совпадение, иначе равенство.
    def pattern_matches?(pattern : Object, value : Object) : Bool
      case pattern
      when Regex    then !pattern.match(value.to_s).nil?
      when Range    then pattern.includes?(value)
      when Class    then value.class.name == pattern.name
      else               pattern == value
      end
    end
  end
end

module Enumerable
  # Ruby Enumerable#grep / grep_v (с опциональным блоком).
  def grep(pattern : Object)
    self.select { |v| ::Ruby::V4.pattern_matches?(pattern, v) }
  end

  def grep(pattern : Object, &block)
    self.select { |v| ::Ruby::V4.pattern_matches?(pattern, v) }.map { |v| yield v }
  end

  def grep_v(pattern : Object)
    self.reject { |v| ::Ruby::V4.pattern_matches?(pattern, v) }
  end

  def grep_v(pattern : Object, &block)
    self.reject { |v| ::Ruby::V4.pattern_matches?(pattern, v) }.map { |v| yield v }
  end
end

class Hash
  # Ruby transform_keys(hash): замена ключей по карте; отсутствующие
  # остаются прежними.
  def transform_keys(map : Hash(K2, K)) : Hash(K2, V) forall K2
    h = Hash(K2, V).new
    each do |k, v|
      h[map.fetch(k) { k.as(K2) }] = v
    end
    h
  end
end

module Ruby
  module V4
    extend self

    # String#lines Ruby; chomp: true — без разделителей в элементах.
    # (без chomp — отдельная перегрузка arity-1 в inspect.cr)
    def lines(s : String, chomp : Bool) : Array(String)
      return lines(s).map(&.chomp) if chomp
      lines(s)
    end
  end
end
