#!/usr/env/bin ruby

#Given a sorted array with duplicates and a number, find the range in the
#form of (startIndex, endIndex) of that number. For example,
#find_range({0 2 3 3 3 10 10},  3) should return (2,4).
#find_range({0 2 3 3 3 10 10},  6) should return (-1,-1).
#The array and the number of duplicates can be large.
#
#ref: http://www.careercup.com/page?pid=software-engineer-in-test-interview-questions

x = 3
a = %w[0 2 3 3 3 10 10].collect {|v| v.to_i}

i1 = a.find_index(x)
if !i1
  print "(-1,-1)"
  return
end

n = a[i1..-1].find_all{|v| v == x}.length
i2 = i1 + n - 1

print "(#{i1},#{i2})"