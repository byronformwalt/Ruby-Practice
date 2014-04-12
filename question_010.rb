#!/usr/bin/env ruby

#Using the following function signature, write a C# function that prints out every combination of indices using Console.WriteLine() whose values add up to a specified sum, n. Values of 0 should be ignored. 

#public void PrintSumCombinations(List<int> numbers, int n); 

#•	It’s okay to use additional private functions to implement the public function 
#•	Be sure to print out the indices of numbers and not the values at those indices 
#•	Don’t worry too much about memory or CPU optimization; focus on correctness 

#To help clarify the problem, calling the function with the following input: 

#List<int> numbers = new List<int> { 1, 1, 2, 2, 4 }; 
#PrintSumCombinations(numbers, 4); 

#Should result in the following console output (the ordering of the different lines isn’t important and may vary by implementation): 

#0 1 2 (i.e. numbers[0] + numbers[1] + numbers[2] = 1 + 1 + 2 = 4) 
#0 1 3 
#2 3 
#4

#ref: http://www.careercup.com/page?pid=software-engineer-in-test-interview-questions
# This question specifies a C# implementation, but I will implement this in Ruby.

class Array
  def sum_combinations(sum)
    numbers = self
    indices = (0..numbers.length-1).to_a

    q = 1.upto(numbers.length).collect do |n|
      s = indices.combination(n).collect do |a|
        a if a.inject(0) {|t,i| t += numbers[i]} == sum
      end.compact
      s.empty? ? nil : s
    end.compact
    solution = []
    q.each{|v| v.each{|r| solution << r}}
    solution    
  end
end

def print_sum_combinations(numbers,sum)
  numbers.sum_combinations(sum).each do |s|
    p s
  end
end

print_sum_combinations([1, 1, 2, 2, 4],4)

