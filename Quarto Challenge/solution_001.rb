#!/usr/bin/env ruby
require 'set'
require 'timeout'

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
        # Initialize the thinking loop.
        while best_place.nil?
          warn "Level #{level}"
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
