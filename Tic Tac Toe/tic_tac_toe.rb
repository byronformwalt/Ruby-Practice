#!/usr/bin/ruby

# Complete the function below to print 2 integers separated by a single space which will be your next move 

class Board < Array
  # For each vacant position on the board, generate all pairs of additional
  # locations that complete a vertical, horizontal, or diagonal line.
  @@c = Array.new(3,0)
  @@c = 3.times.collect{@@c.dup}
  @@c[0][0] = [[[0,1],[0,2]],[[1,0],[2,0]],[[1,1],[2,2]]]
  @@c[1][0] = [[[1,1],[1,2]],[[0,0],[2,0]]]
  @@c[2][0] = [[[2,1],[2,2]],[[1,0],[0,0]],[[1,0],[0,0]]]
  @@c[0][1] = [[[1,1],[2,1]],[[0,0],[0,2]]]
  @@c[1][1] = [[[0,1],[2,1]],[[1,0],[1,2]],[[0,0],[2,2]],[[2,0],[0,2]]]
  @@c[2][1] = [[[1,1],[0,1]],[[2,0],[2,2]]]
  @@c[0][2] = [[[0,0],[0,1]],[[1,2],[2,2]],[[1,1],[2,0]]]
  @@c[1][2] = [[[1,1],[1,0]],[[0,2],[2,2]]]
  @@c[2][2] = [[[2,1],[2,0]],[[1,2],[0,2]],[[1,1],[0,0]]]

  def initialize(*args)
    super(*args)
    if self.length == 0
      3.times{self << ["_"]*3}
    end
  end
  
  def clone
    Board.new(self.collect{|r| r.dup})
  end
  
  def empty?
    b = (self.flatten.join =~ /[^_]/).nil?
  end
  
  def to_s
    s = ""
    self.each{|row| row.each{|v| s << "#{v}"}; s << "\n"}
    s
  end
  
  def find_marks(player)
    # Enumerate coordinates for a particular mark.
    pos = []
    self.each_with_index do |row,j|
      row.each_with_index do |mark,k|
        pos << [j,k] if mark == player
      end
    end
    pos
  end
  ha
  def select_any_corner
    pos = []
    0.upto(2) do |j| 
      0.upto(2) do |k| 
        if j ==  1 || k == 1
          next
        elsif self[j][k] == "_"
          pos << [j,k]
        end
      end
    end
    if !pos.empty?
      pos = pos[rand(pos.length)]
    end
    pos
  end
  
  def where_to_block(opponent)
    # Find a location that needs to be blocked in order to prevent the player
    # from winning.
        
    # Iterate over each position.
    pos = Hash.new([])
    self.each_with_index do |row,j|
      row.each_with_index do |mark,k|
        if mark == opponent
          # Look for a potential for the player to win in the next move.
          @@c[j][k].each do |line|
            s = line.collect{|c| self[c[0]][c[1]]}
            if s.join =~ /#{opponent}_|_#{opponent}/
              #puts "(#{j},#{k}) -> #{line} #{s}"
              pos[[j,k]] = pos[[j,k]] << (s[0] == "_" ? line[0] : line[1])
              pos[[j,k]] = pos[[j,k]].uniq
            end
          end
        end
      end
    end
    pos
  end
     
  def second_move(player)
    # Find a location that enables us to put a second mark in a cleared line.
    prev_pos = self.find_marks(player)
    
    # Iterate over our previously positions.
    pos = []
    prev_pos.each do |j,k|
      # For this position, fetch the possible lines.
      @@c[j][k].each do |line|
        # For this line, determine whether or not there are still two vacant 
        # positions
        s = line.collect{|c| self[c[0]][c[1]]}
        if s.join =~ /__/
          pos << line[0] << line[1]
        end
      end
    end
    return nil if pos.empty?
    
    # Look for a corner in the list of possible positions.
    corner = pos.find{|j,k| (j == 0 || j == 2) && (k == 0 || k == 2)}
    pos = corner.nil? ? pos[rand(pos.length)] : corner
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
    return c if c != "_" && (c == ne && c == sw) || (c == nw && c == se)
    return nil
  end
end

def next_move(player,board)
  opponent = player == "X" ? "O" : "X"  
  
  # SURVIVAL INSTINCTS FIRST.
  
  # Offense
  # If there is an opportunity to win, take it.
  pos = board.where_to_block(player)
  if !pos.empty?
    j,k = pos.first[1][0]
    puts "#{j} #{k}"
    return
  end
  
  # Defense
  # If the opponent has two marks in a row with a possible win, block.
  pos = board.where_to_block(opponent)
  if !pos.empty?
    j,k = pos.first[1][0]
    puts "#{j} #{k}"
    return
  end
  # INITIAL OFFENSIVE STRATEGY IF FIRST TO MOVE.

  # Determine if we are first to go by examining the number of free spaces.
  empty_pos = board.find_marks("_")

  catch(:regular_play) do
    if empty_pos.length.odd?
      pos = board.find_marks(player)
      o_pos = board.find_marks(opponent)

      # We were first to start the game, so go on the offensive.  
      if board.empty?
        # Place a marker in the upper left corner as our first move.
        puts "0 0"
        return
      end
    
      if pos.length == 1
        # This is our second turn.  Determine what tactic we need to use.
        if o_pos[0] == [1,1]
          # The opponent put a marker in the center.  Select the lower right.
          puts "2 2"
          return
        elsif board[0][1] == opponent || board[1][0] == opponent
          # Opponent put a marker adjacent to ours.  Put one in the center.
          puts "1 1"
          return
        elsif board[2][1] == opponent || board[1][2] == opponent
          # Opponent put a marker on opposite edge from our corner.
          # Put a marker on the corner adjacent to our first that is also
          # opposite the edge of our opponent.
          j,k = board[2][1] == opponent ? [0,2] : [2,0]
          puts "#{j} #{k}"
          return
        elsif board[2][2] == opponent
          # Opponent took opposite corner.  Take adjacent corner.
          puts "2 0"
          return
        elsif board[2][0] == opponent || board[0][2] == opponent
          # Opponent took adjacent corner.  Put a marker adajent to our corner
          # but on the opposite edge from our opponent's marker.
          j,k = board[0][2] == opponent ? [1,0] : [0,1]
          puts "#{j} #{k}"
          return
        end
      end
    
      if pos.length == 2
        # This is our third turn.
        if board[1][1] == opponent
          # Our opponent put a marker in the center.  Pick a third corner.
          j,k = empty_pos.find{|j,k| j != 1 && k != 1}
          puts "#{j} #{k}"
          return
        elsif board[1][1] == player
          # We put a marker in the center. Pick the next marker adjacent to
          # our corner.
          j,k = board[0][1] == "_" ? [0,1] : [1,0]
          puts "#{j} #{k}"
          return   
        elsif board[0][2] == player || board[2][0] == player
          # Grab the remaining corner adjacent to the first corner
          j,k = board[0][2] == "_" ? [0,2] : [2,0]
          puts "#{j} #{k}"
          return  
        elsif board[0][2] == "_" || board[2][0] == "_"
          # Take an adjacent corner if available
          j,k = board[0][2] == "_" ? [0,2] : [2,0]
          puts "#{j} #{k}"
          return  
        elsif board[1][1] == "_"
          # Put a marker in the center.
          puts "1 1"
          return
        end    
      end
    end
  end
  
  # FALL-BACK/DEFENSIVE STRATEGY.
  pos = board.find_marks(player)
  o_pos = board.find_marks(opponent)
  
  # If the center square is open, always place the mark in the center.
  if board[1][1] == "_"
    puts "1 1"
    return
  end

  if board[1][1] == player && o_pos.length == 2
    if board[0][0] == opponent && board[2][2] == opponent ||
      board[2][0] == opponent && board[0][2] == opponent
      # If your opponent has two corners, and you have the center, then mark 
      # an edge.
      pos = empty_pos.find_all{|j,k| (j == 1 || k == 1) && (j != 1 || k != 1)}
      j,k = pos[rand(pos.length)]
      puts "#{j} #{k}"
      return
    else
      jc,kc = o_pos.find{|j,k| (j == 0 || j == 2) && (k == 0 || k == 2)}
      if !jc.nil?
        edge = o_pos.dup
        edge.delete([jc,kc])
        je,ke = edge[0]
        if (je == 1 || ke == 1) && (je*ke == 0 || je*ke == 2) && 
          ((jc - je)*(kc - ke)).abs == 2
          # If your opponent has a corner and an opposite edge, and you have the 
          # center, then mark the edge diagonal to your opponents edge and next to 
          # his corner.
          if (kc - ke).abs == 2
            j = jc
            k = 1
            puts "#{j} #{k}"
            return
          elsif (jc - je).abs == 2
            j = 1
            k = kc
            puts "#{j} #{k}"
            return
          end
        end
      end
    end
  end

  # Select any available corner of the opponent has the center and a corner and
  # if we have the opposite corner.
  if empty_pos.length == 6 && board[1][1] == opponent && 
    (board[0][0] != "_" || board[2][0] != "_" || board[0][2] != "_" || board[2][2] != "_")
    # Select any available corner. 
    j,k = board.select_any_corner
    if !j.nil?
      puts "#{j} #{k}"
      return
    end
  end
    
  # Look for a forkable position.  That is a position that is vacant, but if 
  # the opponent were to take it, he would have two ways to win.
  b = board.clone # Make a clone of the board to predict the future.
  empty_pos.each do |j,k|
    b[j][k] = opponent
    pos = b.where_to_block(opponent).max{|a,b| a[1].length <=> b[1].length}
    if !pos.nil?
      if pos[1].length > 1
        # A fork was discovered.  Block it.
        puts "#{j} #{k}"
        return
      end
    end
    b[j][k] = "_" # Erase the move.
  end
     
  # Select any available corner if one is available. 
  j,k = board.select_any_corner
  if !j.nil?
    puts "#{j} #{k}"
    return
  end
  
  # If there is an opportunity to add a second mark with a possible win, take it.
  j,k = board.second_move(player)
  if !j.nil?
    puts "#{j} #{k}"
    return
  end  
  
  # Select any available position.
  pos = board.find_marks("_")
  j,k = pos[rand(pos.length)]
  puts "#{j} #{k}"
  return
end

#If player is X, I'm the first player.
#If player is O, I'm the second player.
player = gets.chomp

#Read the board now. The board is a 3x3 array filled with X, O or _.
board = Board.new(3) { gets.scan /\w/ }

next_move(player,board)    
