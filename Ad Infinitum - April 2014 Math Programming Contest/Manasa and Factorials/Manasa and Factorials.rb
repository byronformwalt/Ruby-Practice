#!/usr/bin/env ruby
require 'stringio'
include Math

$stdin = StringIO.new(
"23
5
246
2
3
4
5
6
7
22
23
24
25
152
153
154
155
156
246
247
248
249
250
10000000000000000")

def greatest_mult(m)
  # Returns the greatest positive integer, q, less than or equal to m such that there exist an integer, r > 1 that satisfies q.mod(5**r) == 0.
  return nil if m < 5**2 || !m.kind_of?(Fixnum)
  r_max = (log(m)/log(5)).floor
  q = 2.upto(r_max).collect{|r| q0 = 5**r (m/q0)*q0}.max
end

def count_roots(m)
  # For all positive integers i <= m, returns a hash containing the number of occurrences of each multiple which has root r of 5.
  r_counts = Hash.new(0)
  return r_counts if m < 25
  r_max = (log(m)/log(5)).floor
  2.upto(r_max) do |r|
    r_counts[r] = m/5**r
  end
  
  # Note that some of the multiples of 5**r0 are also multiples of 5**r1 for r1 > r0.  We offset these counts by subtracting counts from higher values of r.
  nr = r_counts.length
  if nr > 1
    r_counts.keys.reverse[1..-1].each do |r|
      r_counts[r] -= Hash[r_counts.find_all{|k,v| k > r}].values.inject(:+)
    end
  end
  r_counts
end

def count_extras(r_counts)
  n_extra = r_counts.collect do |r,count|
    (r-1)*count
  end.inject(:+)
  n_extra ||= 0
end

def bsearch_for_m(n,m_max,m_min,level = 0)
  # Start by analyzing the midpoint between m_min and m_max.
     
  if m_max - m_min == 5 
    # Terminal search condition.
    n_actual_min = m_min/5 + count_extras(count_roots(m_min))
    n_actual_max = m_max/5 + count_extras(count_roots(m_max))
    m_proposed = n_actual_min >= n ? m_min : m_max
    return m_proposed
  end
  m_proposed = ((m_max + m_min)/10)*5
  n_extra = count_extras(count_roots(m_proposed))
  n_actual = m_proposed/5 + n_extra
    
  if n_actual > n
    return bsearch_for_m(n, m_proposed, m_min, level + 1)
  elsif n_actual < n
    return bsearch_for_m(n, m_max, m_proposed, level + 1)
  else
    # Nailed it.
    return m_proposed
  end
end
    
    
nt = $stdin.gets.to_i
a = $stdin.each_line.collect{|l| l.to_i}
a.each_with_index do |n,i|
  m = bsearch_for_m(n,5*n,0)
  puts m
end