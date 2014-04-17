#!/usr/bin/env ruby

# Write a program to find whether a given number is a perfect square or not. 
# You can only use addition and subtraction operation to find a solution 
# with min. complexity. 
#
# i/p : 25 
# o/p : True 
#
# i/p : 44 
# o/p: False


# Perfect squares follow a difference pattern:
# 0 => 0
# 1 => 1 => 1 difference from 0**2
# 2 => 4 => 3 difference from 1**2
# 3 => 9 => 5 difference from 2**2
# 4 => 16 => 7 difference from 3**2
# .
# .
# .
#
# I will exploit this pattern, as in the preferred solution.

class Fixnum
  def perfect_square?
    delta = 1
    v = 0
    while v < self do
      v += delta
      delta += 2
    end
    v == self
  end
end

x = [-9,-1,0,1,3,4,5,7,9,25,32,48,64,100,225]

x.each do |v|
  s = v.perfect_square? ? "" : " not"
  puts "#{v} is#{s} a perfect square."
end