#!/usr/bin/env ruby

# In an array of unsorted integers (you may assume the array may contain 
# +ve, -ve and 0s), write a function 
#
# int returnNthMax(int[] arr, int n) 
#
# which will return the nth Max number. For e.g. if this is given array 
# {2, -4, 5, 6, 0, 7, -1, 10, 9} and n=1, it should return the max number, 
# 10 and if n=3, it should return 3rd max number, which is: 7.

# ref: http://www.careercup.com/page?pid=software-engineer-in-test-interview-questions&n=2

class Array
  def get_max(n)
    self.sort.reverse[n-1]
  end
end


a = [2, -4, 5, 6, 0, 7, -1, 10, 9]

p a.get_max(1)
p a.get_max(3)