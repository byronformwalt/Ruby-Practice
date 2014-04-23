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
  
  def eval_decision(board,decision,player = @player)
    # Determine whether or not the decision ended the game and 
    # report on it.
    place,pick = decision
    board.place(*place)
    w = board.winner
    r = Report.new
    if w == player
      r.wins += 1
    elsif w > 0
      r.losses += 1
    elsif w == 0
      r.draws += 1
    end
    board.undo
    r
  end
  
  def randomize_decision(board = @board, player = @player)
    p = board.vacancies
    place = p[rand(p.length)]
    u = board.unused
    pick = u[rand(u.length)]
    return Decision.new(place,pick)      
  end
  
  def decide(options = {})
    # This version of the decision agent will use iteration as opposed to recursion.  I think this will lead to a cleaner and more efficient implementation do to the asymmetry in recursion that plagued my previous attempt.  It will also make it easier to keep track of the thinking time.
    player = @player
    opponent = 3 - player
    
    # If there is only one move left to make, then just make it.
    v = @board.vacancies
    if v.length == 1
      warn "There is only one move left to make."
      return Decision.new(v[0],@board.next_piece)
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
    level = 0
    nodes_examined = 0
    begin
      # Make a timed decision.
      Timeout.timeout(options[:thinking_time]) do
        
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
        while best_place.nil?
          warn "Level #{level}"
          
          # For the current level, all we need to know whether or not there is a game-ending decision.  If there is one, we assume that the player responsible for making a decision will end the game.  There is no need to pick a piece for the next player to place if the game ends.  If a game-ending decision is found, there will be no other decisions processed for that level.  Because the board iterators randomly yield picks and places, this greedy approach does not create a weakness exploitable by the opponent.
          
          
          
          # Look for a game-ending situation at this level (win/loss/draw).
          best_place = nil
          b.each_place do |j,k|
            b.place(j,k)
            if b.winner
              # This placement is a game-ender, so there is no need to examine further placements.
              b.undo
              best_place = [j,k]
              break
            end
            b.undo
          end
          if best_place
            # Since the the game ending condition was met for this level
            
          end
         
         ############################################################################## 
          
          
          # Add all possible decisions as children to the current level in the tree.
          nodes_examined = 0
          level_nodes = t.levels[level].to_a
          break if level_nodes.empty?          
          level_nodes.each_with_index do |node,i_node|
            # puts "Analyzing node #{i_node}"
            # Skip this node if the game is over.
            next if !node.data.winner.nil?
            # Select the node (put the board at this node).
            t.activate_node(node)
            b.each do |decision|
              data = DecisionNode.new(b,decision)
              if level == 0 && data.winner && (data.winner % 2) == (player % 2)
                best_place = data.decision.place
                best_pick = data.decision.pick
                raise "winning situation"
              end
              Tree.new(data,node)             
             end
            nodes_examined += 1
          end
          warn "="*50
          level += 1
        end
      end
    rescue Timeout::Error
      warn "Thinking time expired while in level #{level} " +
      "(#{nodes_examined} of #{t.levels[level].length} examined)"
      # Based on what we learned, determine the best possible decision that can be made.
    rescue => e
      case e.message
      when "winning situation"
        warn "Winning situation discovered."
      else
        raise
      end
    end


    raise "DEBUG AGENT."
    
    # We are done discovering new moves.  Now we need to select the best possible move, given our particular situation.  
    
    if best_place
      # Begin with survival instincts at levels 0 and 1 before diving deeper.
      return Decision.new(best_place,best_pick)
    else
      # Generate a report on the ramifications of each decision and generate a scored list.
      warn "Evaluating decisions."
      r = t.report(player)
      if r.empty?
        warn "Logic error in decision agent (no report).  Randomizing decision."
        return randomize_decision
      end
      
      warn " "
      # Find tier 1 decisions (no losses forecasted)
      tier = Hash[r.find_all{|k,v| v.wins > 0 && v.losses == 0}]
      if !tier.empty?
        warn "Found #{tier.length} tier 1 solutions. (some wins, no losses)"
        z = {}
        tier.each{|k,v| z[k] = v.wins.to_f/v.total}
        best_score = z.values.max
        worst_score = z.values.min
        warn "best_score: #{best_score}"
        warn "worst_score: #{worst_score}"
        c = z.find_all{|d,score| score == best_score}
        c = c.sample
        warn "#{c}"
        warn "#{tier[c[0]]}"
        return c[0]
      end
      
      
      # Find tier 2 decisions (no losses)
      tier = Hash[r.find_all{|k,v| v.losses == 0 && v.draws >= 0 && v.wins == 0}]
      if !tier.empty?
        warn "Found #{tier.length} tier 2 solutions. (some draws and undetermined, no losses)"
        # Grab the decision with the least number of draws.
        z = {}
        tier.each{|k,v| z[k] = v.draws/v.total}
        best_score = z.values.max
        worst_score = z.values.min
        warn "best_score: #{best_score}"
        warn "worst_score: #{worst_score}"
        c = z.find_all{|d,score| score == best_score}
        c = c.sample
        warn "#{c}"
        warn "#{tier[c[0]]}"
        return c[0]
      end
      
      
      # Find tier 3 decisions (some wins and some losses)
      tier = Hash[r.find_all{|k,v| v.losses > 0 && v.wins > 0}]
      if !tier.empty?
        warn "Found #{tier.length} tier 3 solutions. (some wins, losses, possibly draws)"
        warn "I am most likely going to lose the game."
        z = {}
        tier.each{|k,v| z[k] = v.eval}
        best_score = z.values.max
        worst_score = z.values.min
        warn "best_score: #{best_score}"
        warn "worst_score: #{worst_score}"
        c = z.find_all{|d,score| score == best_score}
        c = c.sample
        warn "#{c}"
        warn "#{tier[c[0]]}"
        return c[0]
      end
      
      # Find tier 4 decisions (no wins)
      tier = Hash[r.find_all{|k,v| v.wins == 0}]
      if !tier.empty?
        warn "Found #{tier.length} tier 4 solutions. (no wins)"
        z = {}
        tier.each{|k,v| z[k] = -v.losses.to_f/v.total}
        best_score = z.values.max
        worst_score = z.values.min
        warn "best_score: #{best_score}"
        warn "worst_score: #{worst_score}"
        c = z.find_all{|d,score| score == best_score}
        c = c.sample
        warn "#{c}"
        warn "#{tier[c[0]]}"
        return c[0]
      end
      
      warn "All outcomes are indeterminate.  Randomizing decision."
      return randomize_decision
    end
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
        j,k = u[rand(u.length)]
        puts "#{j} #{k}"
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
      d = decide(thinking_time: 5)
      j,k = d.place
      save_pick(d.pick)
      puts "#{j} #{k}"
    else
      raise "Invalid action '#{@action}' specified."
    end
  end
  
end


input = $stdin.each_line.collect{|l| l.chomp}
agent = Agent.new(input)
agent.execute
