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
    a = self.dup
    a << piece if !piece.nil?
    return false if a.any?{|v| v < 0}
    inject(15){|t,a| t &= a} > 0 || inject(0){|t,a| t |= a} == 0
  end
end

class Array
  include Similarity
end

class Set
  include Similarity
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

  def initialize(input = nil,mode = :pick)
    # Imports the raw data from the game engine which indicates the
    # state of the game and the nature of the decision to be made.
    # If no input is given, then an empty board is initialized. 
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
      @next_piece = mode == :place ? input[i] : nil
    end
  end
  
  def []=(j,k,piece)
    # Modifies the board to place the given piece at the specified
    # location.
    @b[j][k] = piece
    @p.delete(piece)
    @next_piece = nil
  end
  
  def winner
    # Returns the winner (1 for player 1, 2 for player 2, 
    # 0 for a tie, or nil if the game is not over).
        
    # Test all possible ways to connect four similar items.
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
end

