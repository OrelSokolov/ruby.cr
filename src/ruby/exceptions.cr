# ruby.cr — исключения Ruby, отсутствующие в Crystal под своими именами.
#
# ZeroDivisionError — алиас DivisionByZeroError (тот же класс, rescue работает
# в обе стороны). StopIteration (Ruby: < IndexError) и FrozenError (< RuntimeError)
# в Crystal нет — определяем с той же иерархией. ArgumentError/KeyError/IndexError/
# RuntimeError/TypeError и др. уже называются в Crystal так же.

# Ruby ZeroDivisionError — целочисленное деление на ноль.
alias ZeroDivisionError = ::DivisionByZeroError

# Ruby StopIteration — остановка итератора (Kernel#loop, Enumerator#next).
class StopIteration < IndexError
  # Значение из stop (Enumerator в Crystal-слое пока не реализован, поэтому
  # union скаляров; nil — по умолчанию).
  @result : String | Int32 | Int64 | Float64 | Bool | Nil

  def initialize(message : String? = nil, result : String | Int32 | Int64 | Float64 | Bool | Nil = nil)
    super(message)
    @result = result
  end

  # Значение, переданное в stop (или возвращённое итератором).
  def result
    @result
  end
end

# Ruby FrozenError — попытка изменить замороженный объект.
class FrozenError < RuntimeError
end
