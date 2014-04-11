#!/usr/bin/env ruby

print "Enter a non-negative integer, then press <ENTER>: "
x = gets.to_i

s = x.to_s.reverse.bytes.each_slice(3).collect do |t| 
  "," + t.pack("c*")
end
s = s.join.reverse.chop
print "\t#{x} -> \"#{s}\"\n"

