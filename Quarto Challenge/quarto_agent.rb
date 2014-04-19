#!/usr/bin/env ruby
require_relative 'quarto_board'

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
      #puts "Max level exceeded.  Make a random decision."
      d = randomize_decision(board,player)
      return d
    end
    if Time.now - t_start > opts[:max_time]
      #puts "Max time exceeded.  Make a random decision."
      raise "TIMEOUT"
      return randomize_decision(board,player)
    end      
    f_check = false
    if level > 0 && board[2,2] >= 0 && board.next_piece == 2
      puts "check"
      f_check = true
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
      # puts "(#{j},#{k}) w: #{w}, player: #{player}" if f_check
      c << [j,k] if w == 0 || w == player 
      puts "c: #{c}" # if f_check
      board.undo
    end
    # puts "c: #{c}" if f_check
    # puts "player: #{player}" if f_check
    # puts "#{board}" if f_check
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
    #puts "Looking for a way to force a win."
    c = {}
    board.vacancies.each do |j,k|
      # if level == 0
      #   j,k = [2,2]
      #   puts "#{board}"
      # end
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
        # if level == 0
        #   break
        # end
      end
      # if level == 0
      #   break
      # end
    end
    # if level == 0
    #   p c
    # end
    # Find the decisions that resulted in the maximum score. 
    score = c.max do |a,b| 
      x = a[1][player].eval - a[1][3-player].eval
      y = b[1][player].eval - b[1][3-player].eval
      x <=> y
    end[1]
    
    # puts "score: #{score}"
    
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
    # if level == 0
    #   puts "place: #{place}, pick: #{pick}, score: #{score}"
    #   puts "player: #{player}"
    # end
    return [place,pick,score]
  end
  
  # def pick(board)
  #   # Determines which piece the opponent should place on the board
  #   # in his next turn.
  #   
  # end
  # 
  # def place(piece,board)
  #   # Determines where to best place a piece on the board, and which
  #   # piece the opponent should place in his next turn.
  #   
  # end
    
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
      #puts "n: #{n} max_level: #{max_level}"
      place,pick,score = decide(@board,Time.now,0,@player,
      max_time: 10, max_level: max_level)
      
      # puts "player: #{@player} place: #{place}, pick: #{pick}, score: #{score}"
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
