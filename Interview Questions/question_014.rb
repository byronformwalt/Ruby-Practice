#!/usr/bin/env ruby

# Write a method to determine if two strings are anagrams of each other. 
# e.g. isAnagram(“secure”, “rescue”) → false 
# e.g. isAnagram(“conifers”, “fir cones”) → true 
# e.g. isAnagram(“google”, “facebook”) → false

class String
  def anagram?(s)
    s1 = self.split("").sort.join.strip
    s2 = s.split("").sort.join.strip
    s1 == s2
  end
end
tests = [["secure", "rescue"],["conifers","fir cones"],["google","facebook"]]
tests.each do |test|
  s1,s2 = test
  puts "\"#{s1}\" <=> \"#{s2}\" are anagrams? #{s1.anagram?(s2)}"
end
