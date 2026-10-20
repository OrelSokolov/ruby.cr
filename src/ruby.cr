# ruby.cr — слой совместимости с Ruby stdlib поверх Crystal.
#
# Пространства: Ruby::V4 (снято с ruby 4.0.4) и Ruby::V3 (ruby 3.4.5) —
# обёртки/алиасы Ruby-API (Time/Date/Random MT19937/Struct/Kernel.format),
# плюс аддитивные переоткрытия ::String/::Int/::Float/::Array/::Hash/::Set/
# ::Range недостающими методами Ruby.
#
# Паритет 1:1 сверяется оракулом twinshot (bin/record-ruby, bin/record-crystal).

require "big"

require "./ruby/mt19937"
require "./ruby/random"
require "./ruby/exceptions"
require "./ruby/kernel"
require "./ruby/inspect"
require "./ruby/rational"
require "./ruby/time"
require "./ruby/date"
require "./ruby/struct"
require "./ruby/pack"
require "./ruby/base64"
require "./ruby/securerandom"
require "./ruby/strscan"

require "./ruby/core_ext/string"
require "./ruby/core_ext/int"
require "./ruby/core_ext/array"
require "./ruby/core_ext/hash"
require "./ruby/core_ext/more"

module Ruby
  # Ruby::V3 повторяет V4 на снятой батарее (отличия только в Set —
  # см. Ruby::V3.set_inspect / set_xor и artifacts diff).
  module V3
    Time     = Ruby::V4::Time
    Date     = Ruby::V4::Date
    DateTime = Ruby::V4::DateTime
    Random   = Ruby::V4::Random
    Struct   = Ruby::V4::Struct

    def self.format(fmt : String, *args)
      Ruby::V4.format(fmt, *args)
    end

    def self.inspect(value)
      if value.is_a?(Set)
        set_inspect(value)
      else
        Ruby::V4.inspect(value)
      end
    end
  end
end
