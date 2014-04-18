#!/usr/bin/env ruby
require 'fileutils'

# 
# # Test for the existence of our state file.
# fname = "state.txt"


class Game
  
  def Game.import_game_state
    fdir = File.dirname(__FILE__) + File::SEPARATOR
    fname = fdir + "state.txt"
    f_new_game = !File.exist?(fname)
  
    if f_new_game # Create a game state file if none exists.
      File.open(fname,"a+") do |f|
        # Initialize game state file here.
      
        f.close
      end
      return nil
    end
  
    # Import the state of the game from the file.
    state = nil
    File.open(fname,"r") do |f|
      f.each do |line|
        # Read in the current state of the game here.
      end
      f.close
    end
    state
  end
  
  def Game.resume(player,pos)
    puts player
    puts pos
  
  end
  
  Game.import_game_state
  
end

class PoliceForce
  def initialize
    @state = import_game_state
  end
  
  def move
    
  end
end

class Robber
  def initialize
    @state = import_game_state
  end
  
  def move
    
  end
end
  

# Read and parse input from STDIN.
player = gets[0] == "C" ? :cops : :robber # Are we the cops or the robber?
x = gets.split.map {|i| i.to_i} # Get all positions.
Position = Struct.new(:cops,:robber)
pos = Position.new
pos.robber = x[0..1] # Parse the robber's position.
pos.cops = x[2..-1].each_slice(2).collect{|s| s} # Parse the cops' positions

# Resume the game from where we left off.
Game.resume(player,pos)
