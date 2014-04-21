#!/usr/bin/env ruby
require_relative 'quarto_board'

class Agent
  def initialize(pathname)
    @cmd = pathname.gsub(/ /,"\\ ")
  end
  
  def execute(input)
    output = nil
    IO.popen(@cmd,"r+") do |pipe|
      pipe.puts(input)
      pipe.close_write
      output = pipe.gets
    end
    output
  end
end

class Game
  @@fdir = File.dirname(__FILE__) + File::SEPARATOR
  
  def initialize(agent_names)
    # Initialize the board and the starting player.
    @board = Board.new
    @player = 1
    @agents = agent_names.collect{|s| Agent.new(@@fdir + s)}
  end
  
  def execute_turn(agent,f_pick_only = false)
    # Interface with a player agent.
    if !f_pick_only
      # Call on the agent to make a PLACE decision.
      t0 = Time.now
      output = agent.execute("#{@player}\nPLACE\n" << @board)
      puts "Player #{@player} responded to PLACE with #{output}" +
      " in #{Time.now - t0} s"
      
      # Place execute the placement.
      j,k = output.split(" ").collect{|v| v.to_i}
      raise "Invalid input." if j.nil? || k.nil?
      @board[j,k] = @board.next_piece
    end
    
    if !@board.game_over?
      # Call on the agent to make a PICK decision.  
      puts "" + @board
          
      puts "#{@player}\nPICK\n" << @board
      t0 = Time.now
      output = agent.execute("#{@player}\nPICK\n" << @board)
      puts "Player #{@player} responded to PICK with #{output}" +
      " in #{Time.now - t0} s"
    
      # Pick the piece selected by the agent.
      @board.next_piece = output.to_i
    end
  end
  
  def play
    # Begin the game by having player 1 select the piece that 
    # player 2 will play.
    @player = 1
    execute_turn(@agents[@player-1],true)
    @player = 2
    
    # Play the game until it is over.
    until @board.game_over? do
      puts "#{@board}\n\n"
      execute_turn(@agents[@player-1])
      @player = 3 - @player
    end
    puts "#{@board}\n\n"
    
    winner = @board.winner
    puts "Game over."
    if winner == 0
      puts "Tie game." 
    else
      puts "Player #{winner} won."
    end
  end
end

agent1 = "solution_000.rb"
agent2 = "solution_001.rb"
game = Game.new([agent1,agent2])
game.play


