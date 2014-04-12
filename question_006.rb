#!/usr/bin/env ruby

# First find out the number 1's in the binary digit of a given integer. Then find out an integer which is greater than the given integer and contains same number of binary 1's

#ref: http://www.careercup.com/question?id=4981417205301248

x = 3


s = x.to_s(2)
puts "x = #{x} ==> #{s}b"
# Find the right most "1" that can shift left one position onto a "0"
a = s.reverse.split("") << "0"
j = 0
i = a.find_index do |v|
   j += 1
   v == "1" && a[j] == "0"
end
a[i] = "0"
a[i+1] = "1"
s2 = a.join.reverse
x2 = s2.to_i(2)
puts "The next integer with the same number of ones in its " +
      "binary representation is x = #{x2} ==> #{s2}b"
      

