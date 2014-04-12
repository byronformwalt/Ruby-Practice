#!/usr/bin/env ruby
require 'matrix'
require 'set'

# Imagine you have a 5x5 matrix containing integers... If any of the elements in this original matrix is 0, then your resultant matrix should have the corresponding row and column filled with 0s. For e.g. if 1st element of 1st row, 2nd element of 2nd row......up to 5th element of 5th row are all 0s, then your resultant 5x5 matrix should be all 0s. Your code should be flexible and work for any size of matrix (not just with 5x5).

# ref: http://www.careercup.com/page?pid=software-engineer-in-test-interview-questions

class Matrix
  
  def []=(j,k,v)
    if j == :all and k.class == Fixnum
      raise "Column index out of range" if k >= self.column_count || k < 0
      if v.is_a?(Array)
        raise "Dimension mismatch" if v.length != self.column_count
        v.each_with_index{|e,j| self.columns[j][k] = e}
        p self.rows.transpose[k]
      else
        self.rows.transpose[k].each_with_index{|e,j| self.rows[j][k] = v}
      end
    elsif k == :all and j.class == Fixnum
      raise "Row index out of range" if j >= self.row_count || j < 0      
      if v.is_a?(Array)
        raise "Dimension mismatch" if v.length != self.row_count
        v.each_with_index{|e,k| self.rows[j][k] = e}
        p self.rows[j]
      else
        self.rows[j].each_with_index{|e,k| self.rows[j][k] = v}
      end
    elsif k == :all and j == :all
      raise "Dimension mismatch" if v.is_a?(Array)
      self.rows.each_with_index{|r,j| r.each_with_index{|c,k| self.rows[j][k] = v}}
    else
      raise "Row index out of range" if j >= self.row_count || j < 0      
      raise "Column index out of range" if k >= self.column_count || k < 0   
      self.rows[j][k] = v
    end
  end
  
  def deplete
    m = self.row_count
    n = self.column_count
    d_rows = Set.new
    d_cols = Set.new
    
    self.each_with_index do |v,j,k|
      if v == 0
        d_rows << j
        d_cols << k
      end
    end
    d_cols.each{|k| self[:all,k] = 0}
    d_rows.each{|j| self[j,:all] = 0}
  end
  
  def to_s
    s = "Matrix:\n"
    s += self.rows.inject("[") do |t,row|
      t = row.inject(t + "\n") do |q,col|
        q += sprintf("%4s, ",col.to_s)
      end.chop.chop
    end + "\n]\n"
  end
end
  
  
m = Matrix.rows([[1,2,3,4,5],[6,7,8,9,10],[6,7,8,9,10],[6,7,8,9,10]])
m[3,3] = 0
m[1,1] = 0
m.deplete

puts "#{m}"
