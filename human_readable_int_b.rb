#!/usr/bin/env ruby

print "Enter a non-negative integer, then press <ENTER>: "
x = gets.to_i

s = x.to_s.reverse
3.step(s.length-1*4/3,3){|i| s.insert((i-1)/3 + i,",")}
s.reverse!

print "\t#{x} -> \"#{s}\"\n"
