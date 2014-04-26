#!/usr/bin/env ruby
require 'stringio'
include Math

# $stdin = StringIO.new(
# "4
# 1
# 2
# 3
# 40")
# 

nt = $stdin.gets.to_i
a = $stdin.each_line.collect{|l| l.to_i}
a.each do |n|
  
  # Start by assuming that no number has more than one factor of five.
  x_max = n*5
  
  # Find the greatest power of five less than or equal to x_max.
  r = (log(x_max)/log(5)).floor
  
  # Compute the extraneous factors of 5.
  n_extra = r*(r+1)/2 - 1
  
  # Compensate for extraneous factors of 5.
  x = (n - n_extra)*5
  
  puts x
end