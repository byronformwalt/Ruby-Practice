#!/usr/bin/env ruby

fdir = File.dirname(__FILE__) + File::SEPARATOR

cmd = "ruby " + (fdir + "tic_tac_toe.rb").gsub(/ /,"\\ ")

class Board < Array
  def initialize(*args)
    super(*args)
    if self.length == 0
      3.times{self << ["_"]*3}
    end
  end
  
  def empty?
    b = (self.flatten.join =~ /[^_]/).nil?
  end
  
  def full?
    b = (self.flatten.join =~ /[_]/).nil?
  end
  
  def to_s
    s = ""
    self.each{|row| row.each{|v| s << "#{v}"}; s << "\n"}
    s
  end
  
  def find_marks(player)
    pos = []
    self.each_with_index do |row,j|
      row.each_with_index do |mark,k|
        pos << [j,k] if mark == player
      end
    end
  end
  
  def winner
    # Check each row
    self.each{|r| return r[0] if r[0] != "_" && r.all?{|v| v == r[0]}}
    # Check each column
    self.transpose.each{|c| return c[0] if c[0] != "_" && c.all?{|v| v == c[0]}}
    # Check both diagonals
    c = self[1][1]
    ne = self[0][0]
    nw = self[0][2]
    se = self[2][0]
    sw = self[2][2]
    return c if c != "_" && ((c == ne && c == sw) || (c == nw && c == se))
    return nil
  end
end


board = Board.new
players = ["X","O"]
winner = nil
i_player = 0
while !winner
  player = players[i_player]
  puts "It's player #{player}'s turn"

  j,k = IO.popen(cmd,'w+') do |f|
    f.puts player
    f.puts "#{board}"
    f.close_write
    s = f.gets
    if s
      s.split(" ").collect{|v| v.to_i}
    end
  end
  puts "=> (#{j},#{k})"
  
  # Update the board
  raise "Position already occupied." if board[j][k] != "_"
  board[j][k] = player
  puts "#{board}"
  puts

  # Check to see if the player won.
  winner = board.winner
  if winner
    puts "Player #{winner} won!"
  end
  
  # Check to see if a tie occured.
  if board.full?
    puts "Game ended in a tie."
    break
  end
  i_player ^= 1
end