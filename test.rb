#!/usr/bin/env ruby

class Score < Array
  def initialize(v = 0)
    super()
    if !v.kind_of?(Fixnum) && !v.kind_of?(Float)
      self[0] = 0.0
      self[1] = 0.0
    elsif v.abs > 1
      self[0] = 0.0
      self[1] = 0.0
    else
      self[0] = v.to_f
      self[1] = 1.0
    end
  end

  def modify(other,sign = 1)
    if other.kind_of?(Array)
      if self[1] <= 0
        v = [sign*other[0].to_f,sign*other[1].to_f]
      elsif other[1] <= 0
        v = self
      else
        v = [self[0]+sign*other[0].to_f,self[1]+sign*other[1].to_f]
      end
      return self if v[1] < 0 || v[0].abs > v[1]
      s = Score.new
      s[0] = v[0]
      s[1] = v[1]
      return s
    else
      v = self + [sign*other.to_f,sign*(1.to_f)]
      return self + [sign*other.to_f,sign*(1.to_f)]
    end
  end    

  def +(other)
    v = modify(other)
    return v
  end
    
  def -(other)
    modify(other,-1)
  end
  
  def /(other)
    v = self.dup
    v[0] = self[0]/other.to_f
    v
  end
  
  def <<(a)
    v = self + a
    self[0] = v[0]
    self[1] = v[1]
    self
  end
  
  def eval
    return 0 if self[1] <= 0 || self[1] < self[0]
    return self[0].to_f/self[1]
  end
end

s = Score.new(0.3)
p s
puts

s << -1
p s
puts

s /= 4
p s
puts


puts s.eval