#!/usr/bin/env ruby

#How to find the adjacent elements of an single dimensional array whose difference is 1; What is the Time Complexity & Auxiliary Space you use ? What type of efficiency can be achieved?

#ref: http://www.careercup.com/page?pid=software-engineer-in-test-interview-questions

a = [2, 1, 3, 4, 5, 8, 7, 8, 9, 10]
p a

class Array
  def diff
    self.each_with_index.collect{|v,i| i < self.length - 1 ? self[i+1] - v : nil}[0..-2]
  end
end

i_unity_diff = a.diff.each_with_index.collect{|d,i| i if d == 1}.compact

puts i_unity_diff