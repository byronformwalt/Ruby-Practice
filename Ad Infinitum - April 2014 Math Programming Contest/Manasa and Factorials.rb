#!/usr/bin/env ruby
require 'stringio'
include Math


$stdin = StringIO.new(
"4
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
250")

$answers = [25,
995,
10,
15,
20,
25,
25,
30,
95,
100,
100,
105,
620,
625,
625,
625,
625,
995,
1000,
1000,
1000,
1005]

def greatest_mult(m)
  # Returns the greatest positive integer, q, less than or equal to m such that there exist an integer, r > 1 that satisfies q.mod(5**r) == 0.
  return nil if m < 5**2 || !m.kind_of?(Fixnum)
  r_max = (log(m)/log(5)).floor
  q = 2.upto(r_max).collect{|r| q0 = 5**r; (m/q0)*q0}.max
end

def count_roots(m)
  # For all positive integers i <= m, returns a hash containing the number of occurrences of each multiple which has root r of 5.
  r_counts = Hash.new(0)
  return if m < 25
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
  r_counts.collect do |r,count|
    (r-1)*count
  end.inject(:+)
end

def compute_m(n)
  m = 5*n
  r_counts = count_roots(m)
  return m if !r_counts
  
  n_extra = count_extras(r_counts)
  n_actual = n + n_extra  
  
  m_proposed = m
  while n < n_actual do
    m = m_proposed
    m_proposed = greatest_mult(m - 1)
    if !m_proposed
      m_proposed = m
      break
    end
    n_extra = count_extras(count_roots(m_proposed))
    n_actual = m_proposed/5 + n_extra
  end
  m = m_proposed
  while n > n_actual do
    m_proposed += 5
    n_extra = count_extras(count_roots(m_proposed))
    n_actual = m_proposed/5 + n_extra    
  end
  m = m_proposed
end

nt = $stdin.gets.to_i
a = $stdin.each_line.collect{|l| l.to_i}
a.each_with_index do |n,i|
  m = compute_m(n)
  puts m
  raise "Wrong answer." if m != $answers[i]
end