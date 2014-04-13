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


class Fixnum
  def perfect_square?
    v = 0
    i = 0
    while v < self do
      i += 1
      v = i.square
    end
    v == self
  end
  
  def square
    # Square a number without doing multiplication.
    v = 0
    for i in (1..self) do
      v += self
    end
    v
  end
  
  def div2
    # Divide by 2 without doing division.
    y = self
    i = 0
    while y > 0
      i += 1
      y -= 2
      i -= 1 if y == 1
    end
    i
  end
  
end


x = [1,3,4,5,7,9,25,32,48,100]

x.each do |v|
  s = v.perfect_square? ? "" : " not"
  puts "#{v} is#{s} a perfect square."
end