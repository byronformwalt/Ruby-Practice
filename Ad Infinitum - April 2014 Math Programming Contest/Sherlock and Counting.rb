#/usr/bin/env ruby
require 'stringio'
include Math
$stdin = StringIO.new(
"2
5 1
5 2
100 25")

nt = $stdin.gets.to_i
a = $stdin.each_line.collect{|l| l.chomp.split(" ").collect{|v| v.to_i}}

a.each do |n,k|
  s = 0

  if k > n/4
    # This is the trivial case where all i on the range [1,n-1] satisfy the criteria.
    s = n-1
    puts s
  else
    # Solve for i*(N-i) = N*K.
    # => i*N - i^2 = N*K
    # => i^2 - i*N + N*K = 0
    # => i = (N +/- sqrt(N^2 - 4*N*K))/2
    # Real solutions to i exist only if K <= N/4, which is guaranteed for this case.
    i_low = ((n - sqrt(n*n - 4*n*k))/2.0).floor
    i_high = ((n + sqrt(n*n - 4*n*k))/2.0).ceil
    #puts "n: #{n}, k: #{k}, i_low: #{i_low}, i_high: #{i_high}"
    s = i_low + n - i_high
    s -= 1 if i_low == i_high
    puts s
  end
  
  # if n < 1000
  #   s = 0
  #   for i in 1...n do
  #     s += 1 if i*(n-i) <= n*k
  #   end
  #   puts "Validation: #{s}"
  # end
end
