#!/usr/bin/env ruby

# Given a sorted integer array and a number, find the start and end indexes 
# of the number in the array. 

# Ex1: Array = {0,0,2,3,3,3,3,4,7,7,9} and Number = 3 --> Output = {3,6} 
# Ex2: Array = {0,0,2,3,3,3,3,4,7,7,9} and Number = 5 --> Output = {-1,-1} 

# Complexity should be less than O(n)

class Array
  def find_range_of_int(v)
    i1 = self.find_index(v) || -1
    i2 = i1 < 0 ? -1 : self.length - 1 - self.reverse.find_index(v)
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
  puts "{#{i1},#{i2}}"
end
