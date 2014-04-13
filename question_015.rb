#!/usr/bin/env ruby

# Given a sorted integer array and a number, find the start and end indexes 
# of the number in the array. 

# Ex1: Array = {0,0,2,3,3,3,3,4,7,7,9} and Number = 3 --> Output = {3,6} 
# Ex2: Array = {0,0,2,3,3,3,3,4,7,7,9} and Number = 5 --> Output = {-1,-1} 

# Complexity should be less than O(n)

class Array
  
  def find_first(v,depth = 0,sign = 1)
    n = self.length
    p = (n/2.0).ceil - 1
    return -1 if depth > 8
    return p if self[p] == v && (n == 1 || self[p-1] != v)
    return -1 if n == 1
    i = self[0..p].find_first(v,depth + 1,sign)
    return i if i >= 0
    i = self[p+1..-1].find_first(v,depth + 1,sign)
    return -1 if i < 0
    r = p + 1 + i 
    return r
  end
  
  def find_last(v,depth = 0)
    p = self.reverse.find_first(v,depth,sign = -1)
    p = p < 0 ? p : self.length - 1 - p
    return p
  end
  
  def find_range_of_int(v)
    i1 = self.find_first(v)
    i2 = self[i1+1..-1].find_last(v)
    i2 = i2 < 0 ? i2 : i2 + i1 + 1
    [i1,i2]
  end
end

a = 
{
  3 => [0,0,2,3,3,3,3,4,7,7,9], 
  5 => [0,0,2,3,3,3,3,4,7,7,9]
}
a.each_pair do |v,a|
  i1,i2 = a.find_range_of_int(v)
  puts "a: #{a}, v: #{v} --> {#{i1},#{i2}}"
end
