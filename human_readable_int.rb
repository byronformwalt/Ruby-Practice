#!/usr/bin/env ruby

print "Enter a non-negative integer, then press <ENTER>: "
x = gets.to_i

i = 0
s = x.to_s.reverse.bytes.each_slice(3).collect do |t| 
  i += 1
  (i > 1 ? "," : "") + t.pack("c*")
end
s = s.join.reverse
print "\t#{x} -> \"#{s}\"\n"
