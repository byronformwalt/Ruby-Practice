#!/usr/bin/env ruby
#
# Given an mxn matrix, design a function that will print out the contents of the matrix in spiral format. 
# Spiral format means for a 5x5 matrix given below:
#
# [ 1 2 3 4 5 ]
# [ 6 7 8 9 0 ]
# [ 1 2 3 4 5 ]
# [ 6 7 8 9 0 ]
# [ 1 2 3 4 5 ]

# path taken is:
#
# [ > > > > > ]
# [ > > > > v ]
# [ ^ ^ > v v ]
# [ ^ ^ < < v ]
# [ < < < < < ]

# where ">" is going right, "v" going down, "<" is going left, "^" is going up.
# The output is:
#
# 1 2 3 4 5 0 5 0 5 4 3 2 1 6 1 6 7 8 9 4 9 8 7 2 3

a = 
[
  [ 1, 2, 3, 4, 5 ],
  [ 6, 7, 8, 9, 0 ],
  [ 1, 2, 3, 4, 5 ],
  [ 6, 7, 8, 9, 0 ],
  [ 1, 2, 3, 4, 5 ]
]

m = a.length
n = a[0].length
b = []
m.times{b << Array.new(n,0)}

s = []
j,k = 0,0
dj,dk = 0,1
kmin,jmin = 0,0
kmax,jmax = n-1,m-1
while true do  
  break if b[j][k] == 1
  s << a[j][k]
  b[j][k] = 1
  if k + dk > kmax
    dk = 0
    dj = 1
    jmin += 1
  elsif k + dk < kmin
    dk = 0
    dj = -1
    jmax -= 1
  elsif j + dj > jmax
    dk = -1
    dj = 0
    kmax -= 1
  elsif j + dj < jmin
    dk = 1
    dj = 0
    kmin += 1
  end
  j += dj
  k += dk
end

p s
