#!/usr/bin/env ruby

# Write a program to generate a fibonacci series.

class Fibonacci
  
  def initialize
    @a = 0
    @b = 1
  end
  
  def next(n = 1)
    return n.times.collect{self.next} if n > 1
    @a, @b = @b, @a+@b
    @a
  end
  
end
    
f = Fibonacci.new


# Test it out
p f.next(20)

f = Fibonacci.new
20.times{p f.next}