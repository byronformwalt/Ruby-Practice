#!/usr/bin/env ruby
require 'set'
require 'timeout'
require_relative 'quarto_board'

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

    #puts "Level #{level}: ID: #{node.id}"
    # Check whether or not this node has any children.  If so, evaluate them first.
    if !node.has_children?
      # Since this node has no children, simply return the score of the node.
      if level.odd? && !node.data.complete
        # Except when the decision was ours and we didn't end the game.  In this case, we treat the outcome as a loss, because our opponent might win in the following move.
        node.data.score = -1.0
      end
    else
      scores = node.each_child.collect do |child|
        eval_decision(child,max_level,level+1).to_f
      end      
      if level.odd?
        score = scores.min
      else
        score = scores.mean
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
  
  def add_nodes(board,parent)
    # Adds all nodes for place and subsequent pick decisions for the next player to move.
    node_count = 0
    board.each do |decision|
      Tree.new(DecisionNode.new(board,decision),parent)
      node_count += 1
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
    begin # Collapsible section of comments...
      # Ok, here is how I intend to evaluate and make decisions about where to play a piece and what piece to choose for my opponent to play durin his next turn.
        
      # First, it is important to realize that any action I take that can win the game is good. (tie or win)  In the case of a tie, it was the last piece to play on the board.  Therefore, the first decision to simply play the last piece in the last available space if that's the only option.
        
      # Next, we build a decision tree one layer at a time.  By keeping track of the total number of nodes analyzed and how many are required to complete the next level, we can estimate whether or not we will have time to complete the next full level of analysis before attempting to start that level.  As a safeguard, we have a timeout.  We can always assume that there is enough time to analyze at least one level of decisions.
        
      # In this decision tree, odd levels correspond to our decisions, while even levels correspond to our opponents.  When I refer to odd levels, it is synonymous with the children of an even level.  In the first level only, if a winning decision is encountered, the thinking process is immediately terminated, and that action is always executed.  Therefore, the first level is initially populated only with placements.  The second part of our decision pertains to pick decisions.  Pick decisions determine which piece our opponent will be playing.  They are part of the first level, but deferred until it is known that there are no winning decisions to be made in the first level.
        
      # If the first level is completely populated with place decisions and it is determined that none are winning decisions, we complete each node by replacing it with a version of that node for every possible pick decision. before advancing to level 2.
        
      # In the second level, we again defer the pick decisions and focus instead on the place decisions, which saves us a lot of time in the beginning of the game, where it is unnecessary to look ahead any further than this level.  This level is populated in the following manner.  For each node in level 1, we repeat the process we used to generate the entirety of level 1, except that we are looking for a situation where we either lose or there is a tie.  In other words, if there is a game-ending scenario in a group of level 2 nodes that branch from a particular level 1 node, then further population of that branch is terminated, and the level 1 node outcome is marked according to the reason the game ended.  If there are no game-ending scenarios, then the corresponding level 1 node is marked as "undetermined" and processing continues on to the branches formed by the remaining level 1 nodes.  If time runs out before level 2 placements are fully populated, the partially or unpopulated branches for level 1 nodes are marked as "incomplete".  Nodes marked "incomplete" are only selected as a last resort, because they could result in the immediate loss of the game if selected.  If a level 2 branch of nodes from a level 1 node contains a lose or tie option, the entire level 2 branch is deleted from the decision tree when the corresponding level 1 node is marked to reflect the status of this branch. 
        
      # Once level 2 placement decisions have been evaluated, we iterate over the level 1 nodes, once more.  This time, we skip each game-terminating option.  For each of the other nodes, we traverse down to the corresponding level 2 branch and examine each of those level 2 nodes.  We replace each of those nodes with a set of nodes for each possible pick decision that our opponent could make.
        
      # Now, with the expanded level 2, we branch to a level 3 set of place decisions.  If any place decision results in a winning scenario for us, we immediately mark the corresponding level 2 node as a winning node for us and delete the level 3 branch.  We follow a corresponding process for ties.  In this manner, we continue populating level 3 with place decisions.  Once level 3 is completely populated with place decision, we replace each node with a set of nodes for each possible subsequent pick decision before moving on to level 4.  Note that at this point, level 3 is only populated with nodes that are completely undetermined outcomes.
        
      # In level 4, we examine each surviving level 3 node and generate every possible corresponding opponent place decision.  For each branch, the first loss or tie terminates further processing on that level 4 branch, and the corresponding level 3 node is marked accordingly.  Once level place 4 processing is completed, it is possible to score level 1 decision nodes.  At this stage of processing, it is possible that a single node from level 1 could have level 3 nodes that result in wins, losses, ties, and other undetermined outcomes.  In order to score the level 1 decisions, we simply count each win as a 1, each loss as a -1, other outcomes as zero, and divide by the total number of level 3 nodes that resulted from the level 1 node.  
        
      # If time remains to progress on to level 5, we build level 5 in the same way we built level 3, and level 6 gets processed in the same manner as level 4.  At this point, the level 5 nodes are the recipients of all game-terminating scores from levels 5 and 6.  Now, when it is time to score level 1 decisions, we compute level 3 scores that branched into levels 5 and/or 6, in the same manner as we did for level 1 scores.  In this scenario, a level 3 score may not be a simple -1, 0, or 1.  Instead, we will end up with a value between -1 and 1.  Level 1 scores will be recalculated in the same way.  This strategy fairly weights possibilities that occur several moves from now.  We may discover that a particular decision will result in a 100% chance of a win 4 or 5 moves later.
        
      # If more time still remains, we can continue to evaluate additional levels, but it is important to fully evaluate levels in pairs once we complete our level 2 analysis.  Otherwise we may be fooled into making an decision that has unintended consequences.  
    end
        
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
            level_nodes_examined += add_nodes(b,parent) if !timed_out
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
        warn "Maximum level achieved to determine outcome of the game."
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
      time_for_next_level = 1.05*nodes_for_next_level*time_per_node
      time_remaining = options[:thinking_time] - time_used
      warn level
      warn t.levels[level].length
      warn "Nodes for next level: #{nodes_for_next_level}"

      warn "Last level I examined #{level_nodes_examined} nodes."
      warn "Estimated time to complete the next level is #{time_for_next_level} s."
      warn "I have #{time_remaining} s more to think."
      if time_remaining < time_for_next_level
        warn "Just doing a quick scan at next level due to lack of time."
        timed_out = true
      end
      warn "="*50
      level += 1
      warn ""
    end

    # Score each possible decision based on future outcomes of the game.
    c = {}
    v = -10
    best_child = nil
    t.each_child do |child|
      decision = child.data.decision
      c[decision] = eval_decision(child,level)
      if c[decision] > v
        v = c[decision]
        best_child = child
      end
    end
    
    # warn "v: #{v}"
    # warn "best_child: #{best_child}"
    # 
    # best_child.each_child do |child|
    #   warn child
    # end
    
    if c.empty?
      warn "All outcomes are indeterminate.  Randomizing decision."
      return randomize_decision
    end
    
    # Find the best decision.
    best_score = c.values.max
    decision = c.find_all{|decision,score| score == best_score}.sample[0]
    warn "Best Score: #{best_score}"    
    
    # Act on the best decision.
    return decision
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
      max_level = n >= 11 ? 1 : n >= 7 ? 2 : n >= 5 ? 7 : 8
      d = decide(thinking_time: 2)
      j,k = d.place
      save_pick(d.pick)
      puts "#{j} #{k}"
    else
      raise "Invalid action '#{@action}' specified."
    end
    puts @board
  end
  
end

input = $stdin.each_line.collect{|l| l.chomp}
agent = Agent.new(input)
agent.execute
