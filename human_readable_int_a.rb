#!/usr/bin/env ruby

print "Enter a non-negative integer, then press <ENTER>: "
x = gets.to_i
s = x.to_s.reverse.gsub(/(?<group>\d\d\d)/,'\k<group>,').reverse.gsub(/^,/,'')
print "\t#{x} -> \"#{s}\"\n"
