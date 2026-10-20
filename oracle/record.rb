#!/usr/bin/env ruby
# frozen_string_literal: true

# Снимает слепки поведения stdlib настоящего Ruby (оракул) в каталог,
# указанный первым аргументом. Читает общий список кейсов record/cases.txt,
# чтобы метки совпадали один-в-один со слепками record/record.cr (Crystal).
#
# Запуск из корня репо (TZ уже установлен обёрткой bin/record-ruby):
#   oracle/record.rb artifacts/ruby-v4

require "date"
require "set"
require "time"
require "base64"
require "strscan"
require "securerandom"

OUT = ARGV[0] or abort "usage: oracle/record.rb DIR"
CASES_FILE = File.expand_path("../record/cases.txt", __dir__)

# Константы для кейсов struct.txt
Point = Struct.new(:x, :y)
KwPoint = Struct.new(:a, :b, keyword_init: true)

# --- разбор cases.txt: {имя файла => [выражения]} ---
cases = {}
file = nil
File.foreach(CASES_FILE) do |line|
  line = line.strip
  next if line.empty?

  if (m = line.match(/\A# file: (.+)\z/))
    file = m[1]
    cases[file] ||= []
  elsif line.start_with?("#")
    next
  elsif file
    cases[file] << line
  else
    abort "выражение вне секции: #{line.inspect}"
  end
end
abort "пустой список кейсов" if cases.empty?

Dir.mkdir(OUT) unless Dir.exist?(OUT)
total = 0
cases.each do |name, exprs|
  path = File.join(OUT, name)
  File.open(path, "w:UTF-8") do |f|
    exprs.each do |expr|
      value =
        begin
          eval(expr, TOPLEVEL_BINDING, CASES_FILE)
        rescue Exception => e # rubocop:disable Lint/RescueException
          "!! #{e.class}"
        end
      f.puts "#{expr} => #{value.inspect}"
      total += 1
    end
  end
end
warn "oracle: #{total} кейсов -> #{OUT}"
