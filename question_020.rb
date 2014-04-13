#!/usr/bin/env ruby 

# Find the first non-repeating character in a string and return its zero-based position.

class String
  def index_of_first_nonrepeating
    j = -1
    self.split("").each_with_index do |c,i| 
      if i == 0
        if self.length == 1
          j = i
          break
        end
        next
      end
      if i == self.length - 1
        if c != self[i-1]
          j = i
        end
        break
      end
      if c != self[i-1] && c != self[i+1]
        j = i
        break
      end
    end
    j
  end
end

s = "aaaaabbbdceccccc"

puts "Index of first non-repeating char in \"#{s}\" is i = #{s.index_of_first_nonrepeating}."
