#!/usr/bin/env ruby

# Print numbers between 45 to 4578 without repeating digits.### 
# Ex: 45-ALLOWED;55(repeatng digits)(-NOT ALLOWED. Frnd tld ths 2 me.he tried diff concepts but interviewer wanted an OPTIMAL ONE..LETS C WHO WRITE THIS WITH SIMPLE LOGIC..

# ref: http://www.careercup.com/page?pid=software-engineer-in-test-interview-questions

require 'set'
include Math
a = 45
b = 4578
n1 = log10(a).floor
n2 = log10(b).ceil

solutions = [a.to_s.reverse.split("").collect{|e| e.to_i}]

d = [*(0..9)]
solutions = []
n1.upto(n2) do |n|
  d.combination(n).collect do |c|
    c.permutation do |e|
      next if e[0] == 0
      v = e.inject(0){|t,v| t = 10*t + v}
      solutions << v if v <= b && v >= a
    end
  end
end
solutions.sort!

p solutions