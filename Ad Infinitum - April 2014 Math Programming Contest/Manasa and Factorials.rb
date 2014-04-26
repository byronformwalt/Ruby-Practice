#!/usr/bin/env ruby
require 'stringio'
include Math

# $stdin = StringIO.new(
# "4
# 1
# 2
# 3
# 40")

nt = $stdin.gets.to_i
a = $stdin.each_line.collect{|l| l.to_i}
a.each do |n|
  tens = 0
  x = 0
  while tens < n do
    x += 1
    if x % 5 == 0
      r = (log(x)/log(5)).floor
      new_tens = 0
      1.upto(r) do |i|
        y = x.to_f/5**i
        if y == y.floor
          tens += 1
        else
          break
        end
      end
    end
  end
  puts x
end