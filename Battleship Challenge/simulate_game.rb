#!/usr/bin/env ruby

require 'matrix'
require 'stringio'

# Setup the game board.
$ship_types ||= [:submarine,:destroyer,:cruiser,:battleship,:carrier]
$ship_hash = Hash.new(:unknown).merge([*(1..$ship_types.length)].zip($ship_types).to_h)

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

class Fixnum
  def ship_type
    $ship_hash[self]
  end  
end

fdir = File.dirname(__FILE__) + File::SEPARATOR
n_rows = nil
n_cols = 10
n_cols.freeze
Placement = Struct.new(:j1,:k1,:j2,:k2)
Ship = Struct.new(:qty,:pegs)


max_inventory = 
{
  submarine:  Ship.new(2,1), 
  destroyer:  Ship.new(2,2),
  cruiser:    Ship.new(1,3),
  battleship: Ship.new(1,4),
  carrier:    Ship.new(1,5)
}

inventory = max_inventory.dup
inventory.each_pair{|k,v| v = v.dup; v.qty = 0; inventory[k] = v}

ships = []
begin
  File.open("#{fdir}test_board.txt",'r') do |f|
    f.each_line do |l|
      #puts l
      if n_rows.nil?
        n_rows = l.to_i
        n_rows.freeze
        next
      end
      a = l.split.collect{|v| v.to_i}
      placement = Placement.new(*a)
      # Determine the type of ship.
      h = placement.j2 - placement.j1 + 1
      w = placement.k2 - placement.k1 + 1
      raise "Ship orientation error." if h <= 0 || w <= 0
      pegs = h*w
      type = pegs.ship_type
      raise "Unknown ship encountered." if type == :unknown
      ship = {type: type, placement: placement, hits: 0, pegs: pegs}
      inventory[type].qty += 1
      raise "Max ship allowance exceeded for #{type}" if inventory[type].qty > max_inventory[type].qty
      ships << ship
    end
  end
rescue StandardError => e
  puts "Error reading input."
  raise e
end
#p ships

# Validate that the placement of ships do not overlap.
o = Array.build2d(n_rows,n_cols,0)
b = Array.build2d(n_rows,n_cols,-1)
ships.each_with_index do |s,i|
  p s
  j1,k1,j2,k2 = s[:placement].values
  j1.upto(j2) do |j|
    k1.upto(k2) do |k|
      b[j][k] = i
      o[j][k] += 1
      raise "Overlapping ships detected." if o[j][k] > 1
    end
  end
  puts
end
impacts = Array.build2d(n_rows,n_cols,false)

# Create an initial state of the board
board = Array.build2d(n_rows,n_cols,'-')

# Iterate until the game ends or until the maximum number of munitions
# have been fired.
max_munitions = n_rows*n_cols
n_munitions = 0
n_destroyed = 0
while n_munitions < max_munitions do
  # Request a decision to be made.
  cmd = "ruby " + (fdir + "decide.rb").gsub(" ",'\\ ')
  j,k = IO.popen(cmd,"w+") do |f|
    f.puts n_rows
    f.puts "#{board.board_to_s}"
    f.close_write
    f.gets
  end.split(" ").collect{|v| v.to_i}
  puts "Agent launched at sector (#{j},#{k})"
  
  # Determine whether or not it was a hit.
  n_munitions += 1
  i = b[j][k]
  if i >= 0
    # A ship was hit.    
    # Find the ship that was hit.
    ship = ships[i]
    puts "#{ship[:type].to_s.capitalize} was hit."
    
    # Update the board.
    if board[j][k] == '-'
      ship[:hits] += 1
      board[j][k] = 'h'
      # Determine whether or not this ship is now destroyed.
      if ship[:hits] >= ship[:pegs]
        # Ship was destroyed.
        puts "#{ship[:type].to_s.capitalize} destroyed."
        n_destroyed += 1
        j1,k1,j2,k2 = ship[:placement].values
        j1.upto(j2) do |j|
          k1.upto(k2) do |k|
            board[j][k] = 'd'
          end
        end
      end  
    else
      puts "Same spot was hit before."
    end
 

    # Determine if the game is over.
    if n_destroyed >= ships.length
      puts "Game over!"
      break
    end
  else
    board[j][k] = 'm'
    puts "Miss"
  end  
  puts board.board_to_s 
  puts  
end
puts board.board_to_s 
puts  
puts "Game ended after #{n_munitions} were fired."

