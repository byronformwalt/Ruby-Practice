#!/usr/bin/env ruby
require 'set'
require 'timeout'

class Fixnum
  def similar?(piece = nil)
    # This method determines whether or not a piece has at least
    # one property in common with another piece.
    return false if !piece
    return false if self == Board::VACANT || piece == Board::VACANT 
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
    return false if a.any?{|v| v == Board::VACANT}
    inject(15){|t,a| t &= a} > 0 || inject(0){|t,a| t |= a} < 15
  end
  
  def similarity(piece = nil)
    # This method determines the total number of bits that are similar between the collection and the provided piece.
    return 0 if self.empty?
    a = self.dup
    a << piece if piece
    return 0 if a.any?{|v| v == Board::VACANT}
    
    # Get the total number of bits that are set among all elements. 
    s = a.inject(15){|t,a| t &= a}.to_s(2).split("")
    n_bset = s.inject(0){|t,a| t += a.to_i}
    s = (15 - a.inject(0){|t,a| t |= a}).to_s(2).split("")
    n_bclear = s.inject(0){|t,a| t += a.to_i}
    n_bset + n_bclear
  end
  
  def find_similar(b = [])
    # Returns a hash whos keys represent the similarity of an item in b to the collection.  The values are the values of b having the level of similarity expressed by the key.
    return [] if !b
    return [] if self.empty? || b.empty?
    g = Hash.new([])
    b.each do |piece|
      s = self.similarity(piece)
      g[s] += [piece] if s > 0
    end
    g
  end
end
 
class Array
  include Similarity
  
  def mean
    inject(:+).to_f/length
  end
end

class Set
  include Similarity
end

class Report
  attr_accessor :wins, :losses, :draws, :undetermined
  def initialize
    @wins,@losses,@draws,@undetermined = 0,0,0,0
  end
  
  def +(a)
    raise "Invalid operand" if !a.kind_of?(Report)
    r = self.class.new
    self.instance_variables.each do |v|
      x = instance_variable_get(v)
      y = a.instance_variable_get(v)
      r.instance_variable_set(v,x+y)
    end
    r
  end
  
  def -(a)
    self + (-a)
  end
  
  def -@
    r = self.class.new
    self.instance_variables.each do |v|
      x = instance_variable_get(v)
      r.instance_variable_set(v,-x)
    end
    r
  end
  
  def total
    total = instance_variables.inject(0.0) do |t,v| 
      t += instance_variable_get(v)
    end
  end
  
  def eval
    # Generate a score for this report.  Draws and undetermined outcomes both get scores of zero.  Wins get a score of 1.  Losses get a score of -1.  The score is the mean of the component scores.
    t = self.total
    t == 0 ? 0 : (@wins - @losses).to_f/t
  end
  
  def to_s
    s = "{wins: #{wins}, losses: #{losses}, draws: #{draws}, "
    s += "undetermined: #{undetermined}}"
  end
  
  def to_str
    self.to_s
  end
end

class Board
  include Enumerable
  attr_reader :moves
  attr_accessor :next_piece
  VACANT = -1
  
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
      @p = (0..15).to_a
      @next_piece = nil
    else
      # Process the input array.
      @b = 4.times.collect do |i|
        input[i].split(" ").collect{|v| v.to_i}
      end
      n = input[4].to_i
      n_expected = n + 5 + (mode == :place ? 1 : 0)
      if input.length != n_expected
        raise "Input length is invalid. " +
        "(Expected #{n_expected} lines, but got #{input.length})"
      end
      @p = 5.upto(n_expected-2).collect{|i| input[i].to_i} 
      @next_piece = mode == :place ? input[n_expected-1].to_i : nil
    end
    @moves = []
  end
  
  def reset
    # Undo the state of the board to its initial state
    # FIXME Add a method for finding the nearest common node to improve the efficiency of this.
    undo(@moves.length)
    self
  end  
  
  def compliment_piece(piece)
    15 - piece
  end
  
  def []=(j,k,piece)
    # Modifies the board to place the given piece at the specified
    # location.
    if !piece
      raise "Placement of nil piece not allowed."
    end
    last_piece = @b[j][k]
    @b[j][k] = piece if piece
    @p.delete(piece)
    @moves << [[j,k],piece] if piece && piece != VACANT
    @next_piece = last_piece == VACANT ? nil : last_piece
    @p.sort!
  end
  
  def next_piece=(piece)
    # Make sure that if a different piece was already selected we
    # move it back onto the unused pieces list before establishing
    # the new next piece.
    if !@next_piece.nil? 
      if @next_piece >= 0
        @p << @next_piece
        @p.sort!
      end
    end
    if !@p.include?(piece)
      warn self
      raise "Piece #{piece ? piece : "<nil>"} is not available to be played."
    end
    # Remove the piece from the list of playable pieces.
    @p.delete(piece)
    @next_piece = piece
  end
  
  def place(j,k)
    # Places the next piece onto the board.
    self[j,k] = @next_piece
  end 
  
  def undo(n = 1)
    # Undoes the last n moves, restoring the state of the board.
    undone_moves = []
    n.times do |i|
      if @next_piece && @next_piece != VACANT
        @p << @next_piece 
        @next_piece = nil
      end
      break if @moves.empty?
      place,pick = @moves.pop
      j,k = place
      self[j,k] = VACANT  # Also pushes piece from that location onto @p.
      self.next_piece = pick # Also pushes prev piece on to the stack.
      undone_moves.unshift([place,pick])
    end
    @p.sort!
    undone_moves
  end
  
  def do_moves(moves)
    moves.each do |move|
      place,pick = move
      j,k = place
      self.next_piece = pick      
      place(j,k)
    end
  end
  
  def winner(f_display = false)
    # Returns the winner (1 for player 1, 2 for player 2, 
    # 0 for a tie, or nil if the game is not over).

    # Test all possible ways to connect four similar items.
    # => p @@w.collect{|c| c.collect{|j,k| @b[j][k]}}
    # => p @@w.collect{|c| c.collect{|j,k| @b[j][k]}.similar?}
    if @@w.any?{|c| c.collect{|j,k| @b[j][k]}.similar?}
      # There is a clear winner.
      if f_display
        i = @@w.find_index{|c| c.collect{|j,k| @b[j][k]}.similar?}
        warn self
        warn "#{@@w[i].collect{|j,k| @b[j][k]}}"
      end
      return vacancies.length.odd? ? 2 : 1 # Since player 2 went first.
    end
    
    # The game was tied.
    if vacancies.length == 0
      warn "Tie game." if f_display
      return 0
    end
    return nil
  end
  
  def game_over?
    # Returns a boolean value indicating whether or not the game 
    # has ended.
    return true if @p.length == 0 && !@next_piece
    return !self.winner.nil?
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
        o << [j,k] if v == VACANT
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
    @b.flatten.all?{|v| v == VACANT}
  end
  
  def [](j,k)
    # Returns the numeric value of the piece occupying the specified
    # location or -1 if it is vacant.
    @b[j][k]
  end
  
  def each_place
    # RANDOMLY iterate over each possible placement.
    return self.to_enum(:each_place) if !block_given?
    vacancies.shuffle.each do |place|
      yield place
    end      
  end
  
  def each_piece
    # Iterate over each possible piece that can be placed on the board, excluding the 
    # next piece.
    return self.to_enum(:each_piece) if !block_given? 
    @p.shuffle.each do |pick|
      yield pick
    end
  end
  
  def each
    # Iterate over every possible move that can be made.
    return self.to_enum if !block_given? 
    self.each_place do |place|
      self.each_piece do |pick|
        yield Decision.new(place,pick)
      end
    end      
  end
  
  def to_s
    # Pretty prints the board to a string.
    s = "Board: \n"

    @b.each_with_index do |r,i| 
      # Print bits 3 and 2 for each element in the current row.
      s << "  "
      r.each_with_index do |e,i| 
        s << (e < 0 ? "X X" : ("%02b" % ((e & 12) >> 2)).split("").join(" "))
        s << "   " if i < 3
      end
      s << "\n"
      
      # Print bits 1 and 0 for each element in the current row.
      s << "  "
      r.each_with_index do |e,i|
        s << (e < 0 ? "X X" : ("%02b" % (e & 3)).split("").join(" ")) 
        s << "   " if i < 3
      end
      s << "\n" 
      s << "\n" if i < 3
    end

    s << "Unused Pieces: \n"
  
    @p.each_slice(4) do |r|
      s << "  "
      r.each_with_index do |e,i| 
        # Print bits 3 and 2 for each element in the current row.
        s << ("%02b" % ((e & 12) >> 2)).split("").join(" ") << "   "
      end
      s << "\n  "
      r.each_with_index do |e,i|     
        s << ("%02b" % (e & 3)).split("").join(" ") << "   "
      end
      s << "\n\n"
    end
    s << "Next Piece: \n"
    if @next_piece
      s << "  " << ("%02b" % ((@next_piece & 12) >> 2)).split("").join(" ") << "\n"
      s << "  " << ("%02b" % (@next_piece & 3)).split("").join(" ")
    else
      s << "<none>"
    end
    s << "\n"
  end
  
  def to_str
    # Dumps to a string the contents of the board in a manner
    # consistent with the output from the game engine.
    pieces = @p.dup
    pieces.delete(@next_piece)
    s = ""
    @b.each{|r| r.each{|v| s << "#{v} "}; s << "\n"}
    s << "#{pieces.length}\n"
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

Decision = Struct.new(:place,:pick)

class DecisionNode
  attr_accessor :complete, :score
  attr_reader :decision
  
  def initialize(board,decision = nil)
    # board is the state of the game board before the decision was made.
    # decision describes what decision to make and also which piece the 
    # next player will place.
    raise "Cannot initialize a decision on a nil board." if !board
    @score = 0.0
    
    # @complete indicates whether or not children of this node have all been evaluated.
    @complete = false  
 
    if !decision
      @decision = Decision.new(nil,board.next_piece)
    else
      @decision = decision.dup
    end    
  end
  
  def to_s
    s = "{place: #{decision.nil? ? "<none>" : decision.place}, "
    s += "pick: #{decision.nil? ? "<none>" : decision.pick}, "
    s += "score: #{score}"
  end
  
  def to_str
    self.to_s
  end
end

class Tree
  # A decision tree contains a game board as the data for the root node.  Each child node contains data describing a combined place and pick decision.  Each node is itself a decision tree.
  include Enumerable
  
  attr_accessor :data, :levels
  attr_reader :id, :children, :parent, :root, :generation
  
  @@id_generator = Random.new
  
  def initialize(data = nil,parent = nil)
    @parent = parent
    @children = Set.new
    @data = data
    @id = @@id_generator.rand(10000000000000000000000000000000)
    
    # Record subtrees by level to support enumeration by level.
    @levels = [Set.new([self]),Set.new]
    # Add this subtree to the specified parent.
    if @parent
      @parent.add_child(self)
      @generation = @parent.generation + 1
      @root = @parent.root
      if @root.levels.length <= @generation
        @root.levels[@generation] = Set.new 
      end
      @root.levels[@generation] << self
    else
      @root = self
      @generation = 0
    end
  end
  
  def parent=(parent) # Protected method
    @parent = parent
  end
    
  def has_children?
    # Returns a boolean value of true if there are children of the root node.
    return !@children.empty? && !@children.nil?
  end
  
  def level_count
    (@levels[-1].empty? ? -1 : 0) + @levels.length
  end
  
  def length
    @levels.flatten.length + (@levels[-1].empty? ? -1 : 0)
  end
  
  def add_child(child)
    # Add an existing subtree to the root node.
    @children << child
    child.parent = self
    #t0 = Time.now
    #propagate(child,:add)
    #puts "  Propagate Timer: #{Time.now - t0} s"
    child
  end
  
  def delete_child(child)
    # Delete a child subtree from the root node.
    @children.delete(child)
    child.parent = nil
    propagate(child,:delete)
    child
  end
  
  def find_child_by_id(id)
    # Note: If you want to find a node that is a grandchild or deeper, use find_node_by_id()
    child = @children.find{|c| c.id == id}
  end
  
  def delete_child_by_id(id)
    # Delete a child from the root node by id.
    child = find_child_by_id(id)
    delete_child(child)
  end
  
  def each_child_with_index
    return self.to_enum(:each_child_with_index) if !block_given?
    @children.each do |child,i|
      yield child,i
    end
  end

  def each_child
    return self.to_enum(:each_child) if !block_given?
    self.each_child_with_index do |child,i|
      yield child
    end
  end
  
  def each_in_level(level)
    # Iterate over every node within the specified level.
    return self.to_enum(:each_in_level) if !block_given?
    @levels[level].each{|node| yield node}
  end
  
  def level(n)
    @levels[n].to_a
  end
  
  def each_with_level
    # Iterates over each node of the tree beginning at the root and working downward one level at a time.
    return self.to_enum(:each_with_level) if !block_given?
    # Start with the root level.
    i = 0
    f_more_levels = true
    while f_more_levels
      f_more_levels = false
      self.each_in_level(i) do |o| 
        f_more_levels ||= o.has_children?
        yield o,i
      end
      i += 1
    end
  end
  
  def each
    # Iterates over each node of the tree beginning at the root and working downward one level at a time.
    return self.to_enum if !block_given?
    # Start with the root level.
    i = 0
    f_more_levels = true
    while f_more_levels
      f_more_levels = false
      self.each_in_level(i) do |o| 
        f_more_levels ||= o.has_children?
        yield o
      end
      i += 1
    end
  end

  def each_level_with_index
    return self.to_enum(:each_level_with_index) if !block_given?
    @levels.each_with_index do |level,i|
      return if level.empty?
      yield level.to_a,i
    end
  end
  
  def each_level
    return self.to_enum(:each_level) if !block_given?
    self.each_with_index do |level|
      yield level.to_a
    end
  end

  def find_node_by_id(id)
    # Returns a reference to the subtree rooted at the specified node
    @levels.each do |level|
      level.each do |node|
        return node if node.id == id
      end
    end
  end
  
  def trace
    # Trace this tree's lineage back to the root tree.
    ancestors = []
    node = self
    while node
      ancestors.unshift(node)
      node = node.parent
    end
    ancestors
  end
  
  def to_s
    # attr_accessor :data, :levels
    # attr_reader :id, :children, :parent
    
    s = self.class.to_s + ":\n"
    s += "  parent: #{parent.nil? ? "<none>" : parent.id}\n"
    s += "  id: #{id}\n"
    s += "  data: \n    #{data}\n"
    s += "  children: \n"
    children.each{|c| s << "    #{c.data}\n"}
    s += "  levels (data): \n"
    @levels.each_with_index do |l,i|
      next if l.empty?
      s += "    #{i}: ["
      l.each{|o| s += o.data.to_s + "\n        "}
      s.strip!
      s += "]\n"
    end
    s
  end
  
  def to_str
    self.to_s
  end
    
  protected :parent=, :add_child
end

class DecisionTree < Tree
  # A DecisionTree class that offers iterators to help evaluate the decision based on its ramifications in a 2-player game.
  
  attr_accessor :active_node
  attr_reader :board
  
  def initialize(board)
    super()
    @board = board.kind_of?(Board) ? board : Board.new
  end
  
  def deactivate_node
    # Deactivate the currently active node, and reset the board.
    board.reset
    @active_node = nil
  end
  
  def activate_node(node)
    b = board.reset  
    # Traverse the tree back to the root. Then Apply every move in the tree from the root to this node.
    ancestors = node.trace
    ancestors.each do |node|
      d = node.data.decision
      b.place(*d.place) if d.place
      b.next_piece = d.pick
    end
    @active_node = node
  end
  
  def report(player,max_level = -1)
    # Generates a consolidated report (of class Report) for all children in the tree.
    if !Set.new(1..2).include?(player)
      # Player must be either 1 or 2.
      raise "Invalid player." 
    end
    opponent = 3 - player
    
    reports = {}
    warn "Generating a list of all nodes..."
    nodes = @levels[1..max_level].collect{|l| l.to_a}.flatten
    warn "Total nodes to analyze: #{nodes.length}"
    nodes.each_with_index do |node,i_node|
      # Build a report for the given node.
      r = Report.new
      case node.data.winner
      when player
        r.wins += 1
      when opponent
        r.losses += 1
      when 0
        r.draws += 1
      else
        # Count the total number of possible decisions that could be made at this point in the game and subtract the number of children to obtain the total number of undetermined outcomes for this level.
        activate_node(node)
        n = board.vacancies.length*board.unused.length
        nc = node.children.length
        r.undetermined += n - nc
      end
      
      # Find the child of the root node that led to this report.
      root_child = node.trace[1]
      decision = root_child.data.decision
      
      # Merge this report with that of the root child.
      if reports.has_key?(decision)
        reports[decision] += r
      else
        reports[decision] = r
      end
      #puts "Finished analyzing node #{i_node}"
      #puts reports[decision]
      #raise "DEBUG." if i_node > 1000
    end
    reports
  end
end


class Agent
  MAX_RUNTIME = 5   # Max amount of time to think per decision (s).
  Report = Struct.new(:wins,:losses,:draws)
  ACTIONS = Set.new([:pick,:place])
  DEFAULT_OPTIONS = {thinking_time: 30}
  
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
  
  def eval_decision(node,max_level,level = 1)
    # Determine whether or not the decision ended the game and 
    # report on it.

    # Check whether or not this node has any children.  If so, evaluate them first.
    if !node.has_children?
      # Since this node has no children, simply return the score of the node.
      if !node.data.complete
        # Except when the decision was incomplete.
        node.data.score = -0.025 #-0.15
      end
    else
      scores = node.each_child.collect do |child|
        eval_decision(child,max_level,level+1).to_f
      end
      if level.odd?
        if level == 1
          score = scores.mean
        else
          score = scores.mean
        end
      else
        score = scores.min
      end
      node.data.score = score
    end
    node.data.score
  end
  
  def randomize_decision(board = @board, player = @player)
    p = board.vacancies
    place = p[rand(p.length)]
    u = board.unused
    pick = u[rand(u.length)]
    return Decision.new(place,pick)      
  end
  
  def evaluate_places(board)
    # Returns nil unless a particular placement will win the game.
    board.each_place do |place|
      board.place(*place)
      w = board.winner
      board.undo
      return place if w
    end
    nil
  end
  
  def add_nodes(board,parent,f_show = false)
    # Adds all nodes for place and subsequent pick decisions for the next player to move.
    node_count = 0
    if f_show
      warn parent
    end
    board.each do |decision|
      Tree.new(DecisionNode.new(board,decision),parent)
      node_count += 1
    end
    if f_show
      warn parent
    end    
    node_count
  end
  
  def decide(options = {})
    # This version of the decision agent will use iteration as opposed to recursion.  I think this will lead to a cleaner and more efficient implementation do to the asymmetry in recursion that plagued my previous attempt.  It will also make it easier to keep track of the thinking time.
    player = @player
    opponent = 3 - player
        
    # If there is only one move left to make, then just make it.
    v = @board.vacancies
    if v.length == 1
      warn "Playing the final piece on the board."
      return Decision.new(v[0],nil)
    end
    
    # If the board is empty, then place the piece at (0,0) and pick the opposite piece.
    if @board.empty?
      return Decision.new([0,0],15 - @board.next_piece)
    end
    
    # If this there is only one piece already on the board, put this one either in (0,0) or in (0,1), whichever is available
    if @board.vacancies.length == 15      
      place = @board.vacant?(0,0) ? [0,0] : [0,1]
      desired_pick = 15 - @board.next_piece
      h = @board.unused.find_similar([desired_pick])
      if h.empty?
        pick = @board.unused.sample
      else
        pick = h[h.keys.max].sample
      end
      return Decision.new(place,pick) 
    end
    
    # If we are asked to place the third piece on the board and (2,2) is vacant, then place it there.
    if @board.vacancies.length == 14 && @board.vacant?(2,2)
      place = [2,2]
      desired_pick = 15 - @board.next_piece
      h = @board.unused.find_similar([desired_pick])
      if h.empty?
        pick = @board.unused.sample
      else
        pick = h[h.keys.max].sample
      end
      return Decision.new(place,pick) 
    end      
      
    # if @board.vacancies.length > 14
    #   
    #   place = 
    #   @board.vacant?(0,0) ? [0,0] : 
    #   @board.vacant?(0,1) ? [0,1] :
    #   @board.vacant?(1,0) ? [1,0] :
    #   @board.vacant?(1,1) ? [1,1] : 
    #   @board.vacancies.sample
    #   
    #   # Pick a piece that has as many attributes in common to (0,0), (0,1), (1,1), and (1,0) as possible.
    #   a = [@board[0,0],@board[1,0],@board[0,1],@board[1,1]]
    #   a = a.find_all{|piece| piece != Board::VACANT}
    #   h = a.find_similar(@board.unused)
    #   if h.empty?
    #     # When there are no similarities possible, use the piece we just placed as the only reference.
    #     h = [@board.next_piece].find_similar(@board.unused)
    #   end
    #   max_similarity = h.keys.max
    #   pick = h[max_similarity].sample
    #   
    #   warn "place: #{place}, pick: #{pick}"
    #   return Decision.new(place,pick) 
    # end
    
    # Validate and merge options.
    bad_opts = options.find_all do |k,v| 
      !DEFAULT_OPTIONS.has_key?(k)
    end.collect{|k,v| k}
    if !bad_opts.empty?
      warn "Ignoring unrecognized option(s) #{bad_opts} provided to " +
      "#{self.class}##{__method__}."
    end    
    options = DEFAULT_OPTIONS.merge(options)

    # Operate on a copy of the board in case something goes wrong.
    b = @board.dup
    best_place,best_pick = nil,nil
    # Create a decision tree.
    t = DecisionTree.new(b)
    t.data = DecisionNode.new(b)
    level = 1
    nodes_examined = 0
    level_nodes_examined = 0
    # Make a timed decision.
    t0 = Time.now
    timed_out = false
        
    # Initialize the thinking loop... iterate over each level until the time expires.
    while true
      warn "Level #{level}"
      level_nodes_examined = 0
      # Iterate over all the nodes from the previous level in the tree.
      f_first = true
      t.levels[level-1].each do |parent|
        t.activate_node(parent)
        if level.odd? # For odd-levels examine our own decisions.
          # First, look at just possible placements to see if any placement will win the game.
          best_place = evaluate_places(b)
          if best_place
            if level == 1
              warn "A winning situation was found"
              return Decision.new(best_place,nil)
            else
              # Mark the parent node responsible for this decision in the as a win for us.
              parent.data.score = 1.0
              parent.data.complete = true
            end
          else
            # Since there was no way to win, populate nodes under the parent for each possible decision.
            level_nodes_examined += add_nodes(b,parent,false) if !timed_out
          end
        else # For even levels, examine our opponent's decisions.
          best_place = evaluate_places(b)
          if best_place
            # Mark the parent node responsible for this decision in the as a win for us.
            parent.data.score = -1.0
            parent.data.complete = true
          else
            # Since there was no way for our opponent to win, populate nodes under the parent for each possible decision.
            level_nodes_examined += add_nodes(b,parent) if !timed_out
          end
        end
        t.deactivate_node
      end
      nodes_examined += level_nodes_examined
      break if timed_out
      
      # Forecast the time required to complete the next level based on how long this level took.
      time_used = Time.now - t0
      time_per_node = time_used/nodes_examined
      
      if !t.levels[level]
        warn "Maximum level of analysis reached."
        break
      end
      
      warn "Level #{level} analysis complete."
      vl = b.vacancies.length
      if vl == 0
        warn "Maximum level achieved."
        break
      elsif vl == 1
        nodes_for_next_level = 1
      else
        nodes_for_next_level = ((b.vacancies.length - level)**2)*(t.levels[level].length)
      end
      time_for_next_level = nodes_for_next_level*time_per_node
      time_remaining = options[:thinking_time] - time_used
      warn level
      warn t.levels[level].length
      warn "Nodes for next level: #{nodes_for_next_level}"

      warn "Last level I examined #{level_nodes_examined} nodes."
      warn "Estimated time to complete the next level is #{time_for_next_level} s."
      warn "I have #{time_remaining} s more to think."
      if time_remaining < time_for_next_level
        timed_out = true
        if time_remaining > time_for_next_level/10        
          warn "Just enough time to do a quick scan at next level due to lack of time."
        else
          warn "Not enough time to scan the next level. Aborting..."
          break
        end
      end
      warn "="*50
      level += 1
      warn ""
    end

    # Score each possible decision based on future outcomes of the game.
    c = {}
    v = -1
    best_child = nil
    t.each_child do |child|
      decision = child.data.decision
      child.data.score = eval_decision(child,level)
      c[decision] = eval_decision(child,level)
      if c[decision] > v
        v = c[decision]
        best_child = child
      end
    end
    
    #warn "v: #{v}"
    #warn "best_child: #{best_child}"
    
    # best_child.each_child do |child|
    #   warn child
    # end
    
    if c.empty?
      warn "All outcomes are indeterminate.  Randomizing decision."
      return randomize_decision
    end
    
    # Find the best decision.
    best_score = c.values.find_all{|v| v > -1.0}.max
    if !best_score
      warn "All decisions lead to a loss."
      return randomize_decision
    end
    
    #c.each{|d| warn "#{d[0]} => #{d[1]}"}
    warn "\nBest Score: #{best_score}"    
    decisions = c.find_all{|decision,score| score == best_score}
    decisions.each{|d| warn d[0]}
    warn " "
    
    # Act on the best decision.
    return decisions.sample[0]
  end
      
  def execute
    # Based on the current state of the game, this method determines
    # how to optimally respond to the external game engine.  This
    # method will execute both place and pick decisions 
    # simultaneously when a placement is requested.  In this case,
    # the agent will store its pick decision on disk for recall
    # later on when it receives a request to make a pick decision.
    @f_abandon_analysis = false
    
    if @board.winner(true)
      raise "The game is already over."
    end
    
    case @action
    when :pick
      if @board.empty?
        # Pick any piece at random if we are player 2 and the board 
        # is empty.
        u = @board.unused
        pick = u[rand(u.length)]
        puts "#{pick}"
        return
      else
        # Whenever we place a piece, we also picked the next one 
        # and we saved it to disk.  Reload our decision.        
        pick = load_pick
        puts pick
      end
    when :place
      n = @board.vacancies.length 
      d = decide(thinking_time: 7)
      j,k = d.place
      save_pick(d.pick)
      warn @board
      puts "#{j} #{k}"
    else
      raise "Invalid action '#{@action}' specified."
    end
  end
  
end

input = $stdin.each_line.collect{|l| l.chomp}
agent = Agent.new(input)
agent.execute
