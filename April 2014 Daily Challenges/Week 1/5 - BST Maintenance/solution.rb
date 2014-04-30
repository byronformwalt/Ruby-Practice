#!/usr/bin/env ruby

# $stdin = 
# "8
# 4 7 3 1 8 2 6 5"

s = $stdin.each_line.collect{|l| l.chomp}
n = s[0].to_i
a = s[1].split(" ").collect{|v| v.to_i}

# Build a tree.  Each member will be added to the lowest node which is closest in value.  If the value is less than an existing node, then it is added as the left child.  If the value is greater than the existing node, then it is added to the right child.

class Tree
  include Enumerable
  attr_accessor :parent, :left, :right, :value, :level, :hash, :root
  
  def initialize(value, parent = nil)
    @root = parent ? parent.root : self
    @hash = {} if !@parent
    @parent = parent
    @value = value
    @left = nil
    @right = nil
    @level = @parent ? parent.level + 1 : 0
    @root.hash[@value] = self
  end
  
  def find(v)
    @root.hash[v]
  end
  
  def add_node(v)
    # Take a value and add it to the appropriate position in the tree.
    best_left = nil
    best_right = nil
    self.each_with_availability do |node,value,pair|
      if v == value
        raise "Value #{v} already in tree."
      end
      left,right = pair      
      if v < value && !node.left
        if !best_left
          best_left = node
        elsif (v - best_left.value).abs > (v - value).abs
          best_left = node
        end 
      elsif v > value && !node.right
        if !best_right
          best_right = node
        elsif (v - best_right.value).abs > (v - value).abs
          best_right = node
        end
      end
    end
    
    if !best_left && ! best_right
      raise "No available nodes remaining on the tree."
    end
    
    node = nil
    if best_left && best_right
      if (v - best_left.value).abs > (v - best_right.value).abs
        node = Tree.new(v,best_right)
        best_right.right = node
      else
        node = Tree.new(v,best_left)
        best_left.left = node
      end
    elsif best_right
      node = Tree.new(v,best_right)
      best_right.right = node
    else
      node = Tree.new(v,best_left)
      best_left.left = node
    end
    node
  end
    
  def each_with_availability
    return self.to_enum(:each_with_availability) if !block_given?
    yield self,@value,[@left ? @left.value : nil,
      @right ? @right.value : nil]
    if @left
      @left.each_with_availability{|n,v,c| yield n,v,c}
    end
    if @right
      @right.each_with_availability{|n,v,c| yield n,v,c}
    end          
  end
  
  def each
    return self.to_enum if !block_given?
    @root.hash.keys.each do |v|
      yield v
    end
  end
  
  def common_ancestor(b)
    # Find the closest common ancestor
    a = self
    ac,bc = a,b
    while ac != bc
      if ac.level == bc.level || ac.level > bc.level
        ac = ac.parent
      else
        bc = bc.parent
      end
    end
    ac
  end
  
  def dist(b)
    ac = self.common_ancestor(b)
    self.level + b.level - 2*ac.level
  end
  
  def to_s
    s = "#{@value}: ["
    s += (@left.nil? ? "nil" : @left.to_s) + ", "
    s += (@right.nil? ? "nil" : @right.to_s) + "]"
  end
  
  protected :hash, :hash=
end

t = Tree.new(a[0])
b = [t]
puts 0
a[1..-1].collect do |v| 
  b << t.add_node(v)
  puts b.combination(2).inject(0){|t,v| t += v[0].dist(v[1])}
end


