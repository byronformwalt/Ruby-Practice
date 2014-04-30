#!/usr/bin/env ruby
require 'stringio'

$stdin = StringIO.new( 
"9 15
#{"6000 "*100000} 200
0
1
2
3
4
5
6
7
8
9
10
11
12
13
14")

class Array
  def diff
    self[0..-2].each_with_index.collect{|a0,i| self[i+1] - a0}
  end
  
  def normalize!
    # Find the min value in the array.
    q = self[0]
    # Compute the mod of each element wrt q.
    self.each_index do |i|
      self[i] %= q if self[i] != q
    end
    # Delete all zeros and duplicates.
    self.delete(0)
    self.sort!
    self.uniq!
    return q if self.empty?
    return self.min
  end
  
  alias_method :old_add, :+
  def +(other)
    if other.kind_of?(Array)
      return self.old_add(other)
    elsif other.respond_to?(:to_a)
      return self + other.to_a
    else
      begin
        a = self.dup
        a.each_index{|i| a[i] += other}
        return a
      rescue
        return self + [other]
      end
    end
  end
end


n,q = gets.split(" ").collect{|s| s.to_i}
a = gets.split(" ").collect{|s| s.to_i}.sort.uniq
queries = q.times.collect{gets.to_i}

# Compute the smallest difference common to base salaries.
d = a.diff.min

queries.each do |k|
  z = a + k
  #p z
  q = z.min
  q = z.normalize!
  while z.length > 1 && z.min > 1
    q = z.normalize!
    #p z
  end
  puts q
  #puts 
end