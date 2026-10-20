# Аддитивные методы Hash/Set/Range из Ruby.

class Hash
  def except(*keys : K) : self
    h = self.class.new
    each { |k, v| h[k] = v unless keys.includes?(k) }
    h
  end

  def slice(*keys : K) : self
    h = self.class.new
    keys.each { |k| h[k] = self[k] if has_key?(k) }
    h
  end

  def key(value) : K?
    key_for?(value)
  end

  def filter_map(&block)
    to_a.filter_map { |pair| yield pair }
  end

  def sum(&block)
    to_a.sum { |pair| yield pair }
  end
end

require "set"

struct Set(T)
  def subset?(other : Set(T)) : Bool
    all? { |v| other.includes?(v) }
  end

  def superset?(other : Set(T)) : Bool
    other.subset?(self)
  end

  def <=(other : Set(T)) : Bool
    subset?(other)
  end

  def <(other : Set(T)) : Bool
    subset?(other) && other.size > size
  end

  def disjoint?(other : Set(T)) : Bool
    none? { |v| other.includes?(v) }
  end

  def intersect?(other : Set(T)) : Bool
    !disjoint?(other)
  end

  def sort : Array(T)
    to_a.sort
  end
end

struct Range(B, E)
  def overlap?(other : Range) : Bool
    return false if self.begin.nil? && other.begin.nil?
    max1 = exclusive? ? (self.end.try &.- 1) : self.end
    max2 = other.exclusive? ? (other.end.try &.- 1) : other.end
    return true if self.begin.nil? || other.begin.nil?
    return false if max1.nil? || max2.nil?
    self.begin <= max2 && other.begin <= max1
  end

  def ===(value) : Bool
    includes?(value)
  end
end

struct Range(B, E)
  def cover?(value) : Bool
    includes?(value)
  end
end

class Hash
  # fetch(key) без значения по умолчанию — KeyError как в Ruby.
  def fetch(key : K)
    fetch(key) { raise KeyError.new("key not found: #{key.inspect}") }
  end
end

class Hash
  # sort_by/min_by/max_by для Hash (Crystal держит их только на Indexable).
  def sort_by(&block)
    to_a.sort_by { |pair| yield pair }
  end

  def min_by(&block)
    to_a.min_by { |pair| yield pair }
  end

  def max_by(&block)
    to_a.max_by { |pair| yield pair }
  end

  def sort
    to_a.sort
  end
end
