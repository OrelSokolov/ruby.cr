# Аддитивные методы Array из Ruby + Ruby-совместимый shuffle.

class Array
  def filter_map(&block)
    map { |x| yield x }.reject { |v| v.nil? }
  end

  # Ruby combination(n) → массив всех сочетаний.
  def combination(n : Int) : Array(Array(T))
    return [[] of T] if n == 0
    return [] of Array(T) if n < 0 || n > size
    out = [] of Array(T)
    each_combination(n) { |c| out << c.to_a }
    out
  end

  def permutation(n : Int) : Array(Array(T))
    return [] of Array(T) if n < 0 || n > size
    out = [] of Array(T)
    each_permutation(n) { |p| out << p.to_a }
    out
  end

  def max(n : Int) : Array(T)
    sort.reverse[0, n]
  end

  def min(n : Int) : Array(T)
    sort[0, n]
  end

  def chunk_while(&block : T, T -> _)
    out = [] of Array(T)
    cur = [] of T
    prev = uninitialized T
    first = true
    each do |x|
      if first || (yield prev, x)
        cur << x
      else
        out << cur
        cur = [x]
      end
      prev = x
      first = false
    end
    out << cur unless cur.empty?
    out
  end

  def slice_when(&block : T, T -> _)
    out = [] of Array(T)
    cur = [] of T
    prev = uninitialized T
    first = true
    each do |x|
      if !first && (yield prev, x)
        out << cur
        cur = [x]
      else
        cur << x
      end
      prev = x
      first = false
    end
    out << cur unless cur.empty?
    out
  end

  def assoc(key)
    each do |x|
      if x.is_a?(Array) && x.size > 0 && x[0] == key
        return x
      end
    end
    nil
  end

  def rassoc(value)
    each do |x|
      if x.is_a?(Array) && x.size > 1 && x[1] == value
        return x
      end
    end
    nil
  end

  def values_at(*ranges : Range(Int, Int)) : Array(T)
    out = [] of T
    ranges.each do |r|
      last = r.exclusive? ? r.end : r.end + 1
      (r.begin...last).each { |i| out << self[i] }
    end
    out
  end

  # Fisher-Yates в порядке Ruby (rb_ary_shuffle) поверх MT19937.
  def shuffle(random : ::Ruby::V4::Random) : Array(T)
    a = dup
    i = a.size
    while i > 1
      i -= 1
      j = random.limited(i.to_u64).to_i32
      a[i], a[j] = a[j], a[i]
    end
    a
  end

  # sample в порядке Ruby (rb_ary_sample): один элемент — limited(len-1).
  def sample(random : ::Ruby::V4::Random) : T?
    return nil if empty?
    self[random.limited((size - 1).to_u64).to_i32]
  end

  # sample(n) в порядке Ruby (rb_ary_sample): j = RAND_UPTO(len-i) из
  # сжимающегося множества — фактический индекс = j + число выбранных ≤ j.
  def sample(n : Int, random : ::Ruby::V4::Random) : Array(T)
    len = size
    chosen = [] of Int32 # фактические индексы в порядке выбора
    n.times do |i|
      j = random.limited((len - 1 - i).to_u64).to_i32
      sorted = chosen.sort
      sorted.each { |c| j += 1 if j >= c }
      chosen << j
    end
    chosen.map { |k| self[k] }
  end
end

class Array
  def drop_while(&block : T -> _)
    out = [] of T
    dropping = true
    each do |x|
      dropping = dropping && (yield x)
      out << x unless dropping
    end
    out
  end

  def take_while(&block : T -> _)
    out = [] of T
    each do |x|
      break unless yield x
      out << x
    end
    out
  end
end

class Array
  # flatten(depth): ограничение глубины. Тип результата — Array(Object):
  # рекурсивные союзы типов не выражаются в Crystal (см. DIFFERENCES.md).
  def flatten(depth : Int)
    ::Ruby::V4.flatten(self, depth)
  end
end

class Array
  # fetch(index) без значения по умолчанию — IndexError как в Ruby
  # (диапазон в сообщении — от -size до size, как в Ruby: -3...3).
  def fetch(index : Int)
    fetch(index) { raise IndexError.new("index #{index} outside of array bounds: #{-size}...#{size}") }
  end
end

module Enumerable
  # inject — алиас reduce как в Ruby (в Crystal есть только reduce).
  def inject(&block)
    reduce { |a, b| yield a, b }
  end

  def inject(init, &block)
    reduce(init) { |a, b| yield a, b }
  end
end
