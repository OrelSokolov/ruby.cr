# Аддитивные методы Int/Float из Ruby, отсутствующие в Crystal.
# %, divmod, remainder, digits, bit_length в Crystal уже совместимы.

struct Int
  def modulo(other : Int) : self
    self % other
  end

  def pow(exponent : Int)
    self ** exponent
  end

  # Модульное возведение в степень: 2.pow(10, 100) => 24.
  def pow(exponent : Int, modulo : Int)
    raise ArgumentError.new("negative exponent") if exponent < 0
    result = 1.to_big_i
    base = to_big_i % modulo.to_big_i
    e = exponent.to_big_i
    m = modulo.to_big_i
    while e > 0
      result = result * base % m if e.odd?
      base = base * base % m
      e >>= 1
    end
    result.to_i64
  end

  def gcdlcm(other : Int)
    {gcd(other), lcm(other)}
  end

  def between?(min : self, max : self) : Bool
    self >= min && self <= max
  end

  # Доступ к биту: 255[0] => 1. Отрицательные индексы считаем от старшего
  # (как в Ruby, где биты бесконечны влево для положительных).
  def [](index : Int) : Int32
    if index >= 0
      (self >> index) & 1
    else
      0
    end
  end
end

struct Float64
  # floor/ceil/truncate с числом знаков. Безаргументные версии в Crystal
  # существуют, поэтому считаем через round(mode:), не вызывая сами себя.
  def floor(digits : Int) : self
    return self if digits >= 16 || nan? || infinite?
    factor = 10.0 ** digits
    (self * factor).round(mode: :to_negative) / factor
  end

  def ceil(digits : Int) : self
    return self if digits >= 16 || nan? || infinite?
    factor = 10.0 ** digits
    (self * factor).round(mode: :to_positive) / factor
  end

  def truncate(digits : Int) : self
    return self if digits >= 16 || nan? || infinite?
    factor = 10.0 ** digits
    (self * factor).round(mode: :to_zero) / factor
  end
end

struct Float32
  def floor(digits : Int) : self
    return self if digits >= 8 || nan? || infinite?
    factor = (10.0 ** digits).to_f32
    (self * factor).round(mode: :to_negative) / factor
  end

  def ceil(digits : Int) : self
    return self if digits >= 8 || nan? || infinite?
    factor = (10.0 ** digits).to_f32
    (self * factor).round(mode: :to_positive) / factor
  end

  def truncate(digits : Int) : self
    return self if digits >= 8 || nan? || infinite?
    factor = (10.0 ** digits).to_f32
    (self * factor).round(mode: :to_zero) / factor
  end
end
