#!/usr/bin/env ruby

# Devise a function that takes an input 'n' (integer) and returns a string that is the
# decimal representation of the number grouped by commas after every 3 digits. You can't
# solve the task using a built-in formatting function that can accomplish the whole
# task on its own.

# Assume: 0 <= n < 1000000000

# 1 -> "1"
# 10 -> "10"
# 100 -> "100"
# 1000 -> "1,000"
# 10000 -> "10,000"
# 100000 -> "100,000"
# 1000000 -> "1,000,000"
# 35235235 -> "35,235,235"

print "Enter a non-negative integer, then press <ENTER>: "
x = gets.to_i
s = x.to_s.reverse.gsub(/(?<group>\d\d\d)/,'\k<group>,').reverse.gsub(/^,/,'')
print "\t#{x} -> \"#{s}\"\n"
