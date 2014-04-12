#!/usr/bin/env ruby

# Imagine we have a large string like this "ABCBAHELLOHOWRACECARAREYOUIAMAIDOINGGOOD" which contains multiple palindromes within it, like ABCBA, RACECAR, ARA, IAMAI etc... Now write a method which will accept this large string and return the largest palindrome from this string. If there are two palindromes which are of same size, it would be sufficient to just return any one of them.

#ref: http://www.careercup.com/question?id=4981417205301248

class String
  def largest_palindrome
    s1  = self.split("")
    s2  = s1.reverse
    p   = ""
    (s2.length-1).times do |i|
      # Determine the max length of aligned letters.
      c = s1.each_with_index.collect do |v1,j|
        v1 == s2[j] ? v1 : "_"
      end
      c = c.join.split("_")
      n = c.collect{|e| e.length}.max || 0
      if n > p.length
        p_new = c.find{|e| e.length == n}
        # Validate that p_new is a palindrome.
        p = p_new if p_new == p_new.reverse
      end
      
      s2.rotate!
    end
    p
  end
end

s = ["abacdgfdcaba","ABCBAHELLOHOWRACECARAREYOUIAMAIDOINGGOOD"]

s.each do |s|
  puts "Largest Palindrome: \"#{s.largest_palindrome}\""
end