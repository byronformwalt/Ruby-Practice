#!/usr/bin/env ruby
require 'stringio'

def print_board(a)
  a.each do |row|
    puts "#{row}"
  end
end

class Array
  def Array.build2d(m,n,v = 0)
    a = Array.new(n,v)
    m.times.collect{a.dup}
  end
  
  def board_to_s
    s = StringIO.new("","w")
    a = self
    a.each do |row|
      s.puts row.join
    end
    s.string
  end
end

# Input the board status.
board = []
i = 0
n_rows = 0
$stdin.each_line do |l|
  if i == 0
    n_rows = l.to_i
    i += 1
    next
  end
  board << l.chomp.split("")
end
n_cols = 10
n_rows.freeze
n_cols.freeze

# Build lists of unstruck, hit, missed, and destroyed sectors on the board
t,h,m,d = [],[],[],[]
board.each_with_index do |row,j|
  row.each_with_index do |s,k|
    case board[j][k]
    when '-'
      t << [j,k] 
    when 'h'
      h << [j,k]
    when 'm'
      m << [j,k]
    when 'd'
      d << [j,k]
    else
      # Whoops.  Unrecognized status.
    end
  end
end

# Target a location.
if h.length == 0
  # If there are no hits then randomly target the next unstruck location.  
  i = rand(t.length).to_i
  j,k = t[i]
else
  # Find the longest series of hits.
  c = h.collect do |s|
    # Using s as a seed, attempt to grow right or down.
    j0,k0 = s
    v_length = 0
    j0.upto(n_rows-1) do |j|
      if board[j][k0] == 'h'
        v_length += 1
      else
        break
      end
    end
    # Verify that there is room to grow vertically.
    growth = Hash.new(0)
    if j0 > 0
      (j0 - 1).downto(0) do |j|
        if board[j][k0] == '-'
          growth[:up] += 1
        else
          break
        end
      end
    end
    if j0 + v_length < n_rows
      (j0 + v_length).upto(n_rows - 1) do |j|
        if board[j][k0] == '-'
          growth[:down] += 1
        else
          break
        end
      end
    end
    
    h_length = 0
    k0.upto(n_cols-1) do |k|
      if board[j0][k] == 'h'
        h_length += 1
      else
        break
      end
    end
    # Verify that there is room to grow horizontally.
    if k0 > 0
      (k0 - 1).downto(0) do |k|
        if board[j0][k] == '-'
          growth[:left] += 1 
        else
          break
        end
      end
    end
    if k0 + h_length < n_rows
      (k0 + h_length).upto(n_cols - 1) do |k|
        if board[j0][k] == '-'
          growth[:right] += 1 
        else
          break
        end
      end
    end

    # Select the direction with the most growth potential.
    if v_length > h_length
      growth.delete(:left)
      growth.delete(:right)
    elsif h_length > v_length
      growth.delete(:up)
      growth.delete(:down)
    end
    direction = :stuck
    if !growth.empty?
      direction = growth.max{|a,b| a[1] <=> b[1]}[0]
    end
    case direction
    when :up,:down
      hits = v_length
    when :left,:right
      hits = h_length
    else
      hits = 0
    end
    
    [hits,direction,s]
  end
  
  # Select the seed with the largest sequence of hits extending down or to 
  #  the right.
  s = c.max{|a,b| a[0] <=> b[0] }
  
  # Translate the data into the coordinates of the next hit.
  j,k = s[2]
  case s[1]
  when :up
    j -= 1
  when :down
    j += s[0]
  when :left
    k -= 1
  when :right
    k += s[0]
  else
    # Unable to grow in any direction.  Randomize target selection.
    # This should never happen
    i = rand(t.length).to_i
    j,k = t[i]    
  end
end

puts "#{j} #{k}"