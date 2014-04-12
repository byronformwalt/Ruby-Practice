#!/usr/bin/env ruby
require 'matrix'
require 'set'

# Imagine you have a 5x5 matrix containing integers... If any of the elements in this original matrix is 0, then your resultant matrix should have the corresponding row and column filled with 0s. For e.g. if 1st element of 1st row, 2nd element of 2nd row......up to 5th element of 5th row are all 0s, then your resultant 5x5 matrix should be all 0s. Your code should be flexible and work for any size of matrix (not just with 5x5).

# ref: http://www.careercup.com/page?pid=software-engineer-in-test-interview-questions

# Simplest approach.

# Initialize a matrix as a 2D array (array of arrays)
m = 5
n = 5

c = Array.new(m*n,1).each_slice(m).collect{|s| s}

# Set some elements to zero.
c[3][4] = 0
c[1][2] = 0


# Zero out the rows/columns which contain any zeros.
del_rows = c.each_with_index.collect{|v,i| i if v.any?{|v| v == 0}}.compact
del_cols= c.transpose.each_with_index.collect{|v,i| i if v.any?{|v| v == 0}}.compact

del_rows.each{|j| c[j].fill(0)}
c = c.transpose
del_cols.each{|k| c[k].fill(0)}
c = c.transpose
puts "#{c}"

