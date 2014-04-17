#!/usr/bin/env ruby 

# Find the first occurrence of a character that occurs only once in a string.

require 'set'
class String
  
  def index_of_first_non_recurring
    h = Hash.new(0)
    self.split("").each do |c|
      h[c] += 1
    end
    s = h.each_pair.collect do |k,v|
      k if v == 1
    end.compact
    v = s.min{|v| self =~ /#{v}/}
    i = self =~ /#{v}/
  end
  
end

s = "abcdefavcdefgb"
i = s.index_of_first_non_recurring

puts "Index of first non-recurring character in \"#{s}\" is i = #{i} (\"#{s[i]}\")."

