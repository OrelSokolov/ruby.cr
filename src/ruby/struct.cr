# Ruby::V4::Struct — макрос-генератор структур с Ruby-поведением:
#   Ruby.struct_def Point, x, y                     # позиционная
#   Ruby.struct_def KwPoint, keyword_init: true, a, b
# Генерируются доступы p.x / p.x = v, [] / []= по индексу и имени,
# to_s/inspect "#<struct Point x=1, y=2>", ==, each, each_pair.
# В Crystal нет Symbol: members → Array(String), to_h → String-ключи.

module Ruby
  macro struct_def(name, *members, keyword_init = false)
    class {{name.id}}
      include ::Ruby::V4::StructAPI

      def struct_members : Array(String)
        [{% for m in members %}{{m.id.stringify}}, {% end %}] of String
      end

      def struct_name : String?
        {{name.stringify}}
      end

      def self.members : Array(String)
        [{% for m in members %}{{m.id.stringify}}, {% end %}] of String
      end

      @values = [] of ::Ruby::V4::Struct::Value

      def initialize(*args : *T) forall T
        vals = [] of ::Ruby::V4::Struct::Value
        {% for m, i in members %}
          vals << (args[{{i}}]? || nil).as(::Ruby::V4::Struct::Value)
        {% end %}
        @values = vals
      end

      def initialize(**named)
        vals = [] of ::Ruby::V4::Struct::Value
        {% for m in members %}
          vals << (named[:{{m.id}}]? || nil).as(::Ruby::V4::Struct::Value)
        {% end %}
        @values = vals
      end

      {% for m, i in members %}
        def {{m.id}}
          @values[{{i}}]
        end

        def {{m.id}}=(v)
          @values[{{i}}] = v.as(::Ruby::V4::Struct::Value)
        end
      {% end %}
    end
  end

  module V4
    module StructAPI
      abstract def struct_members : Array(String)
      abstract def struct_name : String?

      def members : Array(String)
        struct_members
      end

      def values : Array(Struct::Value)
        @values
      end

      def to_a : Array(Struct::Value)
        values
      end

      def to_h : Hash(String, Struct::Value)
        members.zip(values).to_h
      end

      def size : Int32
        members.size
      end

      def length : Int32
        size
      end

      def [](index : Int) : Struct::Value
        values[index]
      end

      def [](name : String) : Struct::Value
        i = members.index(name) || raise KeyError.new("unknown member: #{name}")
        values[i]
      end

      def []=(index : Int, v) : Nil
        @values[index] = v.as(Struct::Value)
      end

      def []=(name : String, v) : Nil
        i = members.index(name) || raise KeyError.new("unknown member: #{name}")
        @values[i] = v.as(Struct::Value)
      end

      def each(&block)
        values.each { |v| yield v }
      end

      def each_pair(&block)
        members.zip(values).each { |(k, v)| yield({k, v}) }
      end

      def ==(other : StructAPI) : Bool
        members == other.members && values == other.values
      end

      def to_s : String
        parts = members.zip(values).map { |k, v| "#{k}=#{Ruby::V4.inspect(v)}" }
        if (n = struct_name)
          "#<struct #{n} #{parts.join(", ")}>".gsub("  ", " ")
        else
          "#<struct #{parts.join(", ")}>"
        end
      end

      def inspect : String
        to_s
      end
    end

    class Struct
      alias Value = Nil | Bool | Int32 | Int64 | Float64 | String

      # Анонимные структуры: Ruby::V4::Struct.anon(["a"]).new(1)
      def self.anon(members : Array(String)) : AnonymousClass
        AnonymousClass.new(members)
      end

      class AnonymousClass
        def initialize(@members : Array(String))
        end

        def new(*values : Struct::Value) : Anonymous
          Anonymous.new(@members, values.to_a)
        end
      end

      class Anonymous
        @vals : Array(Struct::Value)

        def initialize(@member_list : Array(String), vals : Array)
          @vals = vals.map { |v| v.as(Struct::Value) }
        end

        def members : Array(String)
          @member_list
        end

        def values : Array(Struct::Value)
          @vals
        end

        def [](index : Int) : Struct::Value
          @vals[index]
        end

        def [](name : String) : Struct::Value
          i = members.index(name) || raise KeyError.new("unknown member: #{name}")
          @vals[i]
        end

        def []=(index : Int, v) : Nil
          @vals[index] = v.as(Struct::Value)
        end

        def []=(name : String, v) : Nil
          i = members.index(name) || raise KeyError.new("unknown member: #{name}")
          @vals[i] = v.as(Struct::Value)
        end

        def to_s : String
          parts = members.zip(values).map { |k, v| "#{k}=#{Ruby::V4.inspect(v)}" }
          "#<struct #{parts.join(", ")}>"
        end

        def inspect : String
          to_s
        end
      end
    end
  end
end
