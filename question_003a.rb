#!/usr/bin/env ruby

# Imagine you have a 5x5 matrix containing integers... If any of the elements in this original matrix is 0, then your resultant matrix should have the corresponding row and column filled with 0s. For e.g. if 1st element of 1st row, 2nd element of 2nd row......up to 5th element of 5th row are all 0s, then your resultant 5x5 matrix should be all 0s. Your code should be flexible and work for any size of matrix (not just with 5x5).

# ref: http://www.careercup.com/page?pid=software-engineer-in-test-interview-questions

# Another approach.

class Array
  def deplete_rows
    self.collect do |row|
      if row.any?{|v| v == 0}
        row = Array.new(row.length,0)
      end
      row
    end
  end

  def deplete_columns
    self.transpose.deplete_rows.transpose
  end
  
  def deplete
    c1 = self.deplete_columns.flatten
    c2 = self.deplete_rows.flatten
    c = c1.each_with_index.collect do |v1,i|
      [v1,c2[i]].min
    end
    c.each_slice(self[0].length).collect{|s| s}
  end
end

# Initialize a matrix as a 2D array (array of arrays)
m = 5
n = 5

c = Array.new(m*n,1).each_slice(m).collect{|s| s}

# Set some elements to zero.
c[3][3] = 0
c[1][1] = 0

# Zero out the rows/columns which contain any zeros.
puts "#{c}"
puts
c = c.deplete

puts "#{c}"

