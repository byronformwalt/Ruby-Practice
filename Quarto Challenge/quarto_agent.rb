#!/usr/bin/env ruby

require 'set'
class Fixnum
  def similar?(piece)
    # This method determines whether or not a piece has at least
    # one property in common with another piece.
    return false if self < 0 || piece < 0
    self ^ piece != 15
  end
end

module Similarity
  def similar?(piece = nil)
    # This method determines whether or not every piece in a 
    # collection has at least one property in common with another 
    # piece.  If no piece is provided, then the method will just 
    # check for the existence of a common property among the 
    # elements in the collection.
    return false if self.empty?
    a = self.dup
    a << piece if !piece.nil?
    return false if a.any?{|v| v < 0}
    inject(15){|t,a| t &= a} > 0 || inject(0){|t,a| t |= a} < 15
  end
end

class Array
  include Similarity
end

class Set
  include Similarity
end

#!/usr/bin/env ruby

class Score < Array
  def initialize(v = 0)
    super()
    if !v.kind_of?(Fixnum) && !v.kind_of?(Float)
      self[0] = 0.0
      self[1] = 0.0
    elsif v.abs > 1
      self[0] = 0.0
      self[1] = 0.0
    else
      self[0] = v.to_f
      self[1] = 1.0
    end
  end

  def modify(other,sign = 1)
    if other.kind_of?(Array)
      if self[1] <= 0
        v = [sign*other[0].to_f,sign*other[1].to_f]
      elsif other[1] <= 0
        v = self
      else
        v = [self[0]+sign*other[0].to_f,self[1]+sign*other[1].to_f]
      end
      return self if v[1] < 0 || v[0].abs > v[1]
      s = Score.new
      s[0] = v[0]
      s[1] = v[1]
      return s
    else
      v = self + [sign*other.to_f,sign*(1.to_f)]
      return self + [sign*other.to_f,sign*(1.to_f)]
    end
  end    

  def +(other)
    v = modify(other)
    return v
  end
    
  def -(other)
    modify(other,-1)
  end
  
  def <<(a)
    v = self + a
    self[0] = v[0]
    self[1] = v[1]
    self
  end
  
  def eval
    return 0 if self[1] <= 0 || self[1] < self[0]
    return self[0].to_f/self[1]
  end
end

class Board
  attr_accessor :next_piece
  VACANCY = -1
  
  # Build an array to contain all possible arrangements of four
  # consecutive positions on the board.
  @@w = []
  # Four in a row.
  4.times{|j| @@w << 4.times.collect{|k| [j,k]}}
  # Four in a column.
  4.times{|k| @@w << 4.times.collect{|j| [j,k]}}
  # Four diagonally (0,0) to (3,3).
  @@w << 4.times.collect{|i| [i,i]}
  # Four diagonally (0,3) to (3,0).
  @@w << 4.times.collect{|i| [i,3-i]}
  @@w.freeze
  W = @@w
  
  @@corners = [[0,0],[0,3],[3,0],[3,3]].freeze
  CORNERS = @@corners

  def initialize(input = nil,mode = :pick)
    # Imports the raw data from the game engine which indicates the
    # state of the game and the nature of the decision to be made.
    # If no input is given, then an empty board is initialized.
    input = nil if !input.nil? && input.empty?
    if input.nil?
      @b = 4.times.collect{Array.new(4,-1)}
      @p = Set.new((0..15).to_a)
      @next_piece = nil
    else
      # Process the input array.
      @b = 4.times.collect do |i|
        input[i].split(" ").collect{|v| v.to_i}
      end
      i = mode == :pick ? input.length - 1 : input.length - 2
      @p = 4.upto(i).collect{|i| input[i].to_i}
      @next_piece = mode == :place ? input[i+1].to_i : nil
    end
    @moves = []
  end
  
  def compliment_piece(piece)
    15 - piece
  end
  
  def []=(j,k,piece)
    # Modifies the board to place the given piece at the specified
    # location.
    @b[j][k] = piece
    @p.delete(piece)
    @moves << [[j,k],piece]
    @next_piece = nil
  end
  
  def next_piece=(piece)
    # Make sure that if a different piece was already selected we
    # move it back onto the unused pieces list before establishing
    # the new next piece.
    if !@next_piece.nil? 
      if @next_piece >= 0
        @p << @next_piece
        @p = @p.sort
      end
    end
    @next_piece = piece
  end
  
  def place(j,k)
    # Places the next piece onto the board.
    self[j,k] = @next_piece
  end 
  
  def undo
    # Undoes the last move, restoring the state of the board.
    return if @moves.empty?
    place,piece = @moves.pop
    j,k = place
    @b[j][k] = VACANCY
    self.next_piece = piece # Pushes the prev piece on to the stack.
  end
  
  def winner
    # Returns the winner (1 for player 1, 2 for player 2, 
    # 0 for a tie, or nil if the game is not over).
        
    # Test all possible ways to connect four similar items.
    # => p @@w.collect{|c| c.collect{|j,k| @b[j][k]}}
    # => p @@w.collect{|c| c.collect{|j,k| @b[j][k]}.similar?}
    if @@w.any?{|c| c.collect{|j,k| @b[j][k]}.similar?}
      # There is a clear winner.
      return @p.length.odd? ? 1 : 2
    end
    
    # The game was tied.
    return 0 if @p.length == 0
    return nil
  end
  
  def game_over?
    # Returns a boolean value indicating whether or not the game 
    # has ended.
    return true if @p.length == 0
    return !winner.nil?
  end
  
  def unused
    # This method returns an array of unused pieces.
    @p
  end
  
  def vacancies
    # This method returns an array of spaces on the board that are
    # unoccupied.
    o = []
    @b.each_with_index do |r,j| 
      r.each_with_index do |v,k| 
        o << [j,k] if v == VACANCY
      end
    end
    o
  end
  
  def vacant?(j,k)
    # This method returns a boolean value indicating whether or not
    # the specified location is vacant.
    @b[j][k] == -1
  end
  
  def empty?
    @b.flatten.all?{|v| v == VACANCY}
  end
  
  def [](j,k)
    # Returns the numeric value of the piece occupying the specified
    # location or -1 if it is vacant.
    @b[j][k]
  end
  
  def to_s
    # Pretty prints the board to a string.
    s = "Board: \n"
    @b.each{|r| s << "  " << r.to_s << "\n"}
    s << "Unused Pieces: \n  #{@p.to_a}\n"
    s << "Next Piece: #{@next_piece}"
  end
  
  def to_str
    # Dumps to a string the contents of the board in a manner
    # consistent with the output from the game engine.
    pieces = @p.dup.delete(@next_piece)
    s = ""
    @b.each{|r| r.each{|v| s << "#{v} "}; s << "\n"}
    pieces.each{|v| s << "#{v}\n"}
    s << "#{@next_piece}" if !@next_piece.nil?
    s
  end
  
  # Shallow copies make no sense for instances of this class.
  def dup
    clone
  end
  
  def clone
    Marshal.load(Marshal.dump(self))
  end
end

class Agent
  MAX_RUNTIME = 5   # Max amount of time to think per decision (s).
  Report = Struct.new(:wins,:losses,:draws)
  ACTIONS = Set.new([:pick,:place])
  DEFAULT_DECISION_OPTS = {mode: :complex,max_level: 3,max_time: 30}
  
  def initialize(input)
    # Initializes the agent data structure given the raw input 
    # provided by the external game engine.
    @player = input.shift.to_i
    @action = input.shift
    if !@action.nil?
      @action = @action.downcase.to_sym
      @action = nil if !ACTIONS.member?(@action)
    end
    @board = Board.new(input,@action)
  end
  
  def save_pick(pick)
    File.open("pick.obj","wb") do |f|
      f.write(Marshal.dump(pick))
      f.close
    end  
  end
  
  def load_pick
    pick = nil
    File.open("pick.obj","rb") do |f|
      pick = Marshal.load(f)
      f.close
    end
    pick
  end
  
  def score_decision(board,decision,player = @player)
    # Determine whether or not the decision ended the game and 
    # score it.
    place,pick = decision
    board.place(*place)
    w = board.winner
    score = {1 => Score.new,2 => Score.new}
    if w != 0 && !w.nil?
      score[w] = Score.new(1)
    elsif w == 0
      score[0] = Score.new(1)
      score[1] = Score.new(1)
    end
    board.undo
    score
  end
  
  def randomize_decision(board = nil,player = @player)
    board = @board if board.nil?
    p = board.vacancies
    place = p[rand(p.length)]
    u = board.unused
    pick = u[rand(u.length)]
    score = score_decision(board,[place,pick],player)
    return [place,pick,score]      
  end
  
  def decide(board = nil,t_start = Time.now,level = 0,
    player = @player,opts = {})
    raise "NIL PLAYER!" if player.nil?  
    
    # Makes a decision about where to place a given piece on the
    # board and which piece the opponent will place in his next
    # turn.  An arbitrary future state of the board may be specified.
    
    opts = DEFAULT_DECISION_OPTS.merge(opts)
    board = @board if board.nil?
    
    if level > opts[:max_level]
      # Max level exceeded.  Make a random decision.
      d = randomize_decision(board,player)
      return d
    end
    if Time.now - t_start > opts[:max_time]
      # Max time exceeded.  Make a random decision.
      raise "TIMEOUT"
      return randomize_decision(board,player)
    end      
      
    vacancies = board.vacancies
    # If this is the first move of the game, select a corner at 
    # random and a piece that is dichotomous with this one.
    if @board.empty?
      place = Board::CORNERS[rand(Board::CORNERS.length)]
      pick = board.compliment_piece(board.next_piece)
      return [place,pick]
    end
    
    # If only one other piece is on the board, randomize the move.
    if vacancies.length == 15
      return randomize_decision(board,player)
    end
    
    # First, check whether there is a way to win/end the game in the
    # next move.  
    c = []
    vacancies.each do |j,k|
      board.place(j,k)
      w = board.winner
      c << [j,k] if w == 0 || w == player 
      board.undo
    end
    if !c.empty?
      score = {1 => Score.new,2 => Score.new}
      score[player] = Score.new(1)
      return [c[rand(c.length)],-1,score]
    end
    
    # If this is the last piece in the game, just play it.
    if vacancies.length == 1
      pick = -1
      place = vacancies.first
      decision = [place,pick]
      score = score_decision(board,decision,player)
      return [place,pick,score]
    end
    
    # Exit with a random selection if in simple mode.
    if opts[:mode] == :simple
      place = p[rand(p.length)]
      u = board.unused
      pick = u[rand(u.length)]
      score = score_decision(board,[place,pick],player)      
      return [place,pick,score]
    end
    
    # Determine if there is a way that we can prevent our opponent 
    # from winning if there is only one move remaining after ours.
    if board.unused == 1
      place = []
      pick = board.unused
      c = []
      board.vacancies.each do |j,k|
        board.place(j,k)
        place,pick = decide(board,t_start,level + 1,3 - player, 
        opts.merge(mode: :simple))
        
        if board.winner != 3 - player
          # Our opponent did not win with this placement.
          c << [j,k]
        end
        board.undo
      end
      
      if c.empty?
        # We are guaranteed to lose or tie.  Pick the location at 
        # random.
        l = board.vacancies
        place = l[rand(l)]
      else
        # We are guaranteed to win.
        place = c[rand(c)]
      end
      score = score_decision(board,[place,pick],player)
      return [place,pick,score]
    end
      
    # Next, check whether or not there is a way to force our 
    # opponent to create a winning situation for us in the next
    # turn.
    c = {}
    board.vacancies.each do |j,k|
      board.unused.each do |np|
        # if level == 0
        #   np = 2
        # end
        board.place(j,k)        
        board.next_piece = np
        
        place,pick,score = 
        decide(board,t_start,level + 1,3 - player,opts)
        
        key = [[j,k],np]
        if c[key].nil?
          c[key] = score.dup
        else
          c[key][1] += score[1]
          c[key][2] += score[2]
        end
        board.undo
      end
    end
    
    # Find the decisions that resulted in the maximum score. 
    score = c.max do |a,b| 
      x = a[1][player].eval - a[1][3-player].eval
      y = b[1][player].eval - b[1][3-player].eval
      x <=> y
    end[1]
    
    d = c.collect do |a| 
      x = a[1][player].eval - a[1][3-player].eval
      y = score[player].eval - score[3-player].eval
      x == y ? a : nil
    end.compact
    
    # Narrow the selection by maximizing the frequency of the score.
    if score[player].eval - score[3 - player].eval <= 0
      # Minimize the frequency for bad scores.
      freq = d.min{|a,b| a[1][player][1] <=> 
      b[1][player][1]}[1][player][1]
    else
      # Maximize the frequency for non-negative scores.
      freq = d.max{|a,b| a[1][player][1] <=> 
      b[1][player][1]}[1][player][1]
    end    
    c = d.collect{|a| a[1][player][1] == freq ? a : nil}.compact  
    
    # Randomly select from the list of equally good decisions.
    c = c[rand(c.length)]
    score = c[1]
    place = c[0][0]
    pick = c[0][1]
    return [place,pick,score]
  end
      
  def execute
    # Based on the current state of the game, this method determines
    # how to optimally respond to the external game engine.  This
    # method will execute both place and pick decisions 
    # simultaneously when a placement is requested.  In this case,
    # the agent will store its pick decision on disk for recall
    # later on when it receives a request to make a pick decision.
    
    # Pick any piece at random if we are player 2 and the board is 
    # empty.
    if @player == 2 && @board.empty?
      u = @board.unused
      j,k = u[rand(u.length)]
      puts "#{j} #{k}"
      return
    end
    
    # For all other cases, use our decision agent.
    case @action
    when :pick
      # Whenever we place a piece, we also picked the next one and 
      # we saved it to disk.  Reload our decision.
      pick = load_pick
      puts pick
    when :place
      n = @board.vacancies.length 
      max_level = n >= 11 ? 1 : n >= 7 ? 2 : n >= 6 ? 4 : 5
      place,pick,score = decide(@board,Time.now,0,@player,
      max_time: 12, max_level: max_level)
      
      j,k = place
      save_pick(pick)
      puts "#{j} #{k}"
    else
      raise "Invalid action '#{@action}' specified."
    end
  end
end

input = $stdin.each_line.collect{|l| l.chomp}
agent = Agent.new(input)
agent.execute
