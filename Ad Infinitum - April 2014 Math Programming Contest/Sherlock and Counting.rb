#/usr/bin/env ruby
# require 'stringio'
# $stdin = StringIO.new(
# "2
# 5 1
# 5 2")

nt = $stdin.gets.to_i
a = $stdin.each_line.collect{|l| l.chomp.split(" ").collect{|v| v.to_i}}

a.each do |n,k|
  s = 0
  for i in 1...n do
    s += 1 if i*(n-i) <= n*k
  end
  puts s
end
