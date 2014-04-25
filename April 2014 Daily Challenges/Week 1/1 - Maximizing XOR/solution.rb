#!/usr/bin/env ruby

# $stdin = "1
# 10"

l,r = $stdin.each_line.collect{|l| l.chomp.to_i}
v = (l..r).to_a.product((l..r).to_a).collect{|a,b| a^b}.max
puts v