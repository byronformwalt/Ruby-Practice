#!/usr/bin/env ruby

# Given a 2D array of 1 and 0, Find the largest rectangle (may not be square) which is made up of all 1 or 0.

# ref: http://www.careercup.com/page?pid=software-engineer-in-test-interview-questions

class Array
  def find_largest_block
    b = self
    m = b.length
    n = b[0].length

    # Find all the "1"s
    i = b.each_with_index.collect do |r,j|
      r.each_with_index.collect do |c,k|
        [j,k] if c == 1
      end
    end.flatten.compact.each_slice(2).collect{|s| s}

    blocks = i.collect do |pair|
      j0,k0 = pair[0..1]

      # Compute the maximum possible block width and height
      h_max = m - j0
      w_max = n - k0
  
      # Iterate over all possible block widths
      s = [0,0,0]
      k0.upto(k0+w_max-1) do |k|
        # Determine the tallest block that can be composed at this width.
        w = k - k0 + 1
        h = 0
        j0.upto(j0 + h_max - 1) do |j|
          if b[j][k] == 1
            h = j - j0 + 1
          else
            break
          end
        end
        h_max = h
        a = w*h
        s = [a,w,h] if a > s[0]
      end
      s
    end

    block_sizes = blocks.transpose[0]
    a_max = block_sizes.max
    i_max = block_sizes.find_index{|a| a == a_max}
    w,h = blocks[i_max][1..2]
    j,k = i[i_max][0..1]

    puts "The largest contiguous block is at (#{j},#{k}) and measures #{h} x #{w}"
 
  end
end

# Build some test cases
img = [
  [
    [0,0,0,0,0,0],
    [0,0,1,1,0,0],
    [0,0,1,1,0,0],
    [0,0,0,0,0,0]
  ],

  [
    [0,1,0,0,0,0],
    [0,0,1,1,0,0],
    [0,0,1,1,0,0],
    [0,0,0,0,1,0]
  ],

  [
    [0,1,0,0,0,0],
    [0,0,1,1,0,0],
    [0,0,1,1,1,0],
    [0,0,0,0,1,0]
  ],

  [
    [0,1,0,0,0,0],
    [0,0,1,1,1,0],
    [0,0,1,1,1,0],
    [0,0,0,0,1,0]
  ],

  [
    [1,1,1,1,1,1],
    [0,1,1,1,1,1],
    [0,0,1,1,1,0],
    [0,0,0,0,1,0]
  ],

  [
    [1,1,0,0,1,1],
    [1,1,0,1,1,1],
    [0,0,0,1,1,1],
    [0,0,0,1,1,1]
  ]
]


img.each do |b|
  puts "\nExamining block: #{b}\n\n"
  b.find_largest_block
end

