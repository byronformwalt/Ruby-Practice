#!/usr/bin/env ruby
require_relative 'quarto_board'

class Agent
  MAX_RUNTIME = 5   # Max amount of time to think per decision (s).
  Report = Struct.new(:wins,:losses,:draws)
  ACTIONS = Set.new([:pick,:place]).freeze
  
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
    puts "Saved pick decision to disk."    
  end
  
  def load_pick
    pick = nil
    File.open("pick.obj","rb") do |f|
      pick = Marshal.load(f)
      f.close
    end
    puts "Loaded pick decision from disk."
    pick
  end
  
  def simulate(board,piece,t_max,t_start = Time.now)
    # Internally simulates the remainder of the game, as if
    # this agent were playing both sides of the game.  This
    # method reports the number of wins/losses incurred by 
    # each side.  The simulation terminates after t_max seconds.
    report = Report.new(0,0,0)
    
    
    
    report
  end
  
  def decide(board = nil,mode = :complex)
    # Makes a decision about where to place a given piece on the
    # board and which piece the opponent will place in his next
    # turn.  An arbitrary future state of the board may be specified.
    board = @board if board.nil?
    
    # If this is the first move of the game, select a corner at 
    # random and a piece that is dichotomous with this one.
    if @board.empty?
      place = Board::CORNERS[rand(Board::CORNERS.length)]
      pick = board.compliment_piece(board.next_piece)
      return [place,pick]
    end
    
    # First, check whether there is a way to win/end the game in the
    # next move.  
    c = []
    board.vacancies.each do |j,k|
      np = board.next_piece
      board[j,k] = np
      c << [j,k] if board.game_over?
      board[j,k] = Board::VACANCY
      board.next_piece = np
    end
    return [c[rand(c.length)],-1] if !c.empty?
    
    # Exit with a random selection if in simple mode.
    if mode == :simple
      p = board.vacancies
      place = p[rand(p.length)]
      u = board.unused
      pick = u[rand(u.length)]
      return [place,pick]
    end
    
    # Determine if there is a way that we can prevent our opponent 
    # from winning if there is only one move remaining after ours.
    if board.unused == 1
      place = []
      pick = board.unused
      c = []
      b = board.dup
      b.vacancies.each do |j,k|
        np = board.next_piece
        b[j,k] = np
        place,pick = decide(b,:simple)
        if b.winner != 3 - @player
          # Our opponent did not win with this placement.
          c << [j,k]
        end
        b[j,k] = Board::VACANCY
        board.next_piece = np
      end
      
      if c.empty?
        # We are guaranteed to lose.  Pick the location at random.
        l = b.vacancies
        place = l[rand(l)]
      else
        place = c[rand(c)]
      end
      return [place,pick]
    end
      
    
    # Next, check whether or not there is a way to force our 
    # opponent to create a winning situation for us in the next
    # turn.
    puts "Looking for a way to force a win."
    board.vacancies.each do |j,k|
      b = board.dup
      b[j,k] = b.next_piece
      b.unused.each do |np|
        b.next_piece = np
        place,pick = decide(b)
        
      end
      
      
    end
    
    
    []
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
      place,pick = decide
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
