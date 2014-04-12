#!/usr/bin/env ruby

print "Enter a non-negative integer, then press <ENTER>: "
x = gets.to_i

s = x.to_s.reverse.split("").inject("") do |t,c| 
  t + ((t.length + 1) % 4 == 0 ? ",": "") + c
end.reverse
print "\t#{x} -> \"#{s}\"\n"


