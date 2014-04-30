require 'set'

# 
# $stdin = "4 4 
# aaab
# 1 a
# 2 b
# 3 c
# 4 d"

# Parse Input.
line = $stdin.each_line.collect{|l| l}
# Note: Ruby 2.x supports String#lines, but 1.9.3 does not.
n,nq = line[0].split(" ").collect{|v| v.to_i}
s = line[1].chomp

queries = 2.upto(1+nq).collect do |i|
  a = line[i].chomp.split(" ")
  p = a[0].to_i
  c = a[1]
  [p,c]
end

r = []
# Process Queries.
queries.each do |q|
  p,c = q
  s[p-1] = c
  r = Set.new
  1.upto(n) do |w|  # For each width.
    0.upto(n - w) do |u| # For each shift.
      r << s[u..(u+w-1)]
    end
  end
  puts r.length
end