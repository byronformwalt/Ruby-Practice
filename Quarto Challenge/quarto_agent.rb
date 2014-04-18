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
    @action = input.shift.downcase.to_sym
    @action = nil if !ACTIONS.member?(@action)
    @board = Board.new(input)
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
  
  def simulate(board,piece,t_max)
    # Internally simulates the remainder of the game, as if
    # this agent were playing both sides of the game.  This
    # method reports the number of wins/losses incurred by 
    # each side.  The simulation terminates after t_max seconds.
    report = Report.new(0,0,0)
    
    
    
    report
  end
  
  def decide(board = nil)
    # Makes a decision about where to place a given piece on the
    # board and which piece the opponent will place in his next
    # turn.  An arbitrary future state of the board may be specified.
    board = @board if board.nil?
    
    []
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
      return u[rand(u.length)]
    end
    
    # For all other cases, use our decision agent.
    case @action
    when :pick
      # Whenever we place a piece, we also picked the next one and we
      # saved it to disk.  Reload our decision.
      
    when :place
      decision = decide
    else
      raise "Invalid action specified."
    end
  end
  
  def pick(board)
    # Determines which piece the opponent should place on the board
    # in his next turn.
    
  end
  
  def place(piece,board)
    # Determines where to best place a piece on the board, and which
    # piece the opponent should place in his next turn.
    
  end
  
end

input = $stdin.each_line.collect{|l| l.chomp}
agent = Agent.new(input)
agent.execute
